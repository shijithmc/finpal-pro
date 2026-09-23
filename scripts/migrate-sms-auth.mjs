#!/usr/bin/env node
import { randomBytes } from 'node:crypto';
import { spawn } from 'node:child_process';
import { writeFile } from 'node:fs/promises';
import { pathToFileURL } from 'node:url';

// AWS CLI input goes through stdin: generated passwords never appear in command
// arguments, process listings, normal output, or the readiness receipt.
export function awsCaller(region) {
  return (service, operation, input) => new Promise((resolve, reject) => {
    const child = spawn('aws', [service, operation, '--region', region,
      '--cli-input-json', 'file:///dev/stdin', '--output', 'json', '--no-cli-pager'],
    { stdio: ['pipe', 'pipe', 'pipe'] });
    let output = '';
    child.stdout.on('data', data => { output += data; });
    child.stderr.resume(); // Do not relay potentially sensitive CLI diagnostics.
    child.on('error', () => reject(new Error(`Could not run AWS CLI: ${operation}`)));
    child.on('close', code => {
      if (code !== 0) return reject(new Error(`AWS operation failed: ${operation} (exit ${code})`));
      try { resolve(output.trim() ? JSON.parse(output) : {}); }
      catch { reject(new Error(`Invalid AWS CLI response: ${operation}`)); }
    });
    child.stdin.on('error', () => {});
    child.stdin.end(JSON.stringify(input));
  });
}

async function verifyLocked(callAws, { account, region, poolId }) {
  const identity = await callAws('sts', 'get-caller-identity', {});
  if (identity.Account !== account || !poolId.startsWith(`${region}_`))
    throw new Error('AWS account or pool region does not match the explicit target.');

  const { Stacks = [] } = await callAws('cloudformation', 'describe-stacks', {
    StackName: 'FinpalFoundation',
  });
  const stack = Stacks[0];
  const outputs = Object.fromEntries((stack?.Outputs ?? []).map(item => [item.OutputKey, item.OutputValue]));
  if (!['CREATE_COMPLETE', 'UPDATE_COMPLETE'].includes(stack?.StackStatus)
      || outputs.AuthStageOutput !== 'locked' || outputs.UserPoolIdOutput !== poolId)
    throw new Error('FinpalFoundation must have completed the locked auth stage for this pool.');

  const { UserPool: pool } = await callAws('cognito-idp', 'describe-user-pool', { UserPoolId: poolId });
  if (pool?.AdminCreateUserConfig?.AllowAdminCreateUserOnly !== true
      || ['PreSignUp', 'DefineAuthChallenge', 'CreateAuthChallenge', 'VerifyAuthChallengeResponse']
        .some(name => pool?.LambdaConfig?.[name]))
    throw new Error('Pool sign-up or a legacy authentication trigger remains enabled.');

  const clients = [];
  let token;
  do {
    const page = await callAws('cognito-idp', 'list-user-pool-clients', {
      UserPoolId: poolId, MaxResults: 60, ...(token ? { NextToken: token } : {}),
    });
    clients.push(...(page.UserPoolClients ?? []));
    token = page.NextToken;
  } while (token);
  if (clients.length !== 1 || clients[0].ClientId !== outputs.UserPoolClientIdOutput)
    throw new Error('Legacy or unmanaged app clients remain. Only the locked replacement client may exist.');
  const { UserPoolClient: client } = await callAws('cognito-idp', 'describe-user-pool-client', {
    UserPoolId: poolId, ClientId: clients[0].ClientId,
  });
  if (JSON.stringify(client?.ExplicitAuthFlows) !== JSON.stringify(['ALLOW_REFRESH_TOKEN_AUTH'])
      || client?.AllowedOAuthFlowsUserPoolClient === true)
    throw new Error('The replacement app client still permits sign-in.');
  return clients[0].ClientId;
}

async function listUsers(callAws, poolId) {
  const users = [];
  let token;
  do {
    const page = await callAws('cognito-idp', 'list-users', {
      UserPoolId: poolId, Limit: 60, ...(token ? { PaginationToken: token } : {}),
    });
    users.push(...(page.Users ?? []));
    token = page.PaginationToken;
  } while (token);
  for (const user of users) {
    if (!user.Username || !['CONFIRMED', 'UNCONFIRMED', 'RESET_REQUIRED', 'FORCE_CHANGE_PASSWORD']
      .includes(user.UserStatus))
      throw new Error('Pool contains an unexpected user type. Review it before migration.');
  }
  return users;
}

export async function migrate({ callAws, account, region, poolId, apply = false,
  now = () => new Date(), makePassword = () => `Aa1!${randomBytes(32).toString('base64url')}` }) {
  const target = { account, region, poolId };
  const clientId = await verifyLocked(callAws, target);
  const users = await listUsers(callAws, poolId);
  if (!apply) return { dryRun: true, users: users.length };

  for (const user of users) {
    await callAws('cognito-idp', 'admin-set-user-password', {
      UserPoolId: poolId, Username: user.Username, Password: makePassword(), Permanent: true,
    });
    await callAws('cognito-idp', 'admin-user-global-sign-out', {
      UserPoolId: poolId, Username: user.Username,
    });
  }
  await verifyLocked(callAws, target);
  const after = await listUsers(callAws, poolId);
  const names = entries => entries.map(user => user.Username).sort();
  if (JSON.stringify(names(after)) !== JSON.stringify(names(users)))
    throw new Error('Pool membership changed during migration. Keep it locked and rerun.');

  return { schemaVersion: 1, migrationComplete: true, authStage: 'locked',
    stackName: 'FinpalFoundation', ...target, clientId,
    migratedUsers: users.length, completedAt: now().toISOString() };
}

async function main(args) {
  const options = {};
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--apply') options.apply = true;
    else if (['--account', '--region', '--pool-id', '--receipt'].includes(args[i]) && args[i + 1])
      options[args[i].slice(2)] = args[++i];
    else throw new Error(`Unknown or incomplete option: ${args[i]}`);
  }
  const { account, region, 'pool-id': poolId, receipt, apply = false } = options;
  if (!/^\d{12}$/.test(account ?? '') || !region || !poolId || (apply && !receipt))
    throw new Error('Usage: node scripts/migrate-sms-auth.mjs --account ID --region REGION --pool-id POOL [--apply --receipt PATH]');
  const result = await migrate({ callAws: awsCaller(region), account, region, poolId, apply });
  if (apply) {
    await writeFile(receipt, `${JSON.stringify(result, null, 2)}\n`, { flag: 'wx', mode: 0o600 });
    process.stdout.write(`Migrated ${result.migratedUsers} users. Readiness receipt: ${receipt}\n`);
  } else {
    process.stdout.write(`Dry run: ${result.users} users require password retirement and session revocation. No changes made.\n`);
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main(process.argv.slice(2)).catch(error => {
    process.stderr.write(`${error.message}\n`);
    process.exitCode = 1;
  });
}
