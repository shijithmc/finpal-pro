import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const cdkDirectory = fileURLToPath(new URL('..', import.meta.url));

function synth(t, { stage, receipt, pool = 'ap-south-1_test' } = {}) {
  const directory = mkdtempSync(join(tmpdir(), 'finpal-auth-guard-'));
  t.after(() => rmSync(directory, { recursive: true, force: true }));
  const env = { ...process.env, CDK_DEFAULT_ACCOUNT: '123456789012',
    CDK_DEFAULT_REGION: 'ap-south-1', CDK_OUTDIR: join(directory, 'assembly') };
  delete env.AUTH_STAGE;
  delete env.AUTH_MIGRATION_RECEIPT;
  delete env.AUTH_USER_POOL_ID;
  if (stage) env.AUTH_STAGE = stage;
  if (receipt) {
    const path = join(directory, 'test-only-receipt.json');
    writeFileSync(path, JSON.stringify(receipt));
    env.AUTH_MIGRATION_RECEIPT = path;
    env.AUTH_USER_POOL_ID = pool;
  }
  const run = () => execFileSync('dotnet', ['run', '--project', 'src/Cdk/Cdk.csproj',
    '--configuration', 'Release', '--no-build'], { cwd: cdkDirectory, env, stdio: 'pipe' });
  return { run, directory };
}

const validReceipt = () => ({ schemaVersion: 1, migrationComplete: true,
  authStage: 'locked', stackName: 'FinpalFoundation', account: '123456789012',
  region: 'ap-south-1', poolId: 'ap-south-1_test', clientId: 'test-client',
  migratedUsers: 3, completedAt: new Date().toISOString() });

for (const [name, options, message] of [
  ['missing stage', {}, /Set AUTH_STAGE=locked/],
  ['OTP without receipt', { stage: 'otp' }, /OTP activation requires/],
  ['wrong-account receipt', { stage: 'otp', receipt: { ...validReceipt(), account: '000000000000' } }, /SMS migration receipt is invalid/],
  ['wrong-pool receipt', { stage: 'otp', receipt: validReceipt(), pool: 'ap-south-1_other' }, /SMS migration receipt is invalid/],
  ['incomplete migration', { stage: 'otp', receipt: { ...validReceipt(), migrationComplete: false } }, /SMS migration receipt is invalid/],
  ['future receipt', { stage: 'otp', receipt: { ...validReceipt(), completedAt: '2099-01-01T00:00:00Z' } }, /SMS migration receipt is invalid/],
]) {
  test(`synthesis refuses ${name}`, t => {
    const { run } = synth(t, options);
    assert.throws(run, error => message.test(String(error.stderr)));
  });
}

test('completed migration activates OTP without replacing the user pool or locked client', t => {
  const { run, directory } = synth(t, { stage: 'otp', receipt: validReceipt() });
  run();
  const template = JSON.parse(readFileSync(join(directory, 'assembly', 'FinpalFoundation.template.json')));
  assert.equal(template.Outputs.AuthStageOutput.Value, 'otp');
  const pool = template.Resources.UserPoolPhone8BB2D86D;
  assert.equal(pool.Properties.AdminCreateUserConfig.AllowAdminCreateUserOnly, false);
  assert.equal(pool.DeletionPolicy, 'Retain');
  assert.deepEqual(template.Resources.MobileOtpClientA723F0FA.Properties.ExplicitAuthFlows,
    ['ALLOW_USER_AUTH', 'ALLOW_REFRESH_TOKEN_AUTH']);
});
