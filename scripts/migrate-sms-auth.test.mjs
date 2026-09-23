import assert from 'node:assert/strict';
import test from 'node:test';
import { migrate } from './migrate-sms-auth.mjs';

const target = { account: '123456789012', region: 'ap-south-1', poolId: 'ap-south-1_test' };
const users = [
  { Username: 'first', UserStatus: 'CONFIRMED' },
  { Username: 'second', UserStatus: 'UNCONFIRMED' },
];

function fixture(overrides = {}) {
  const calls = [];
  let listPass = 0;
  const responses = {
    'get-caller-identity': { Account: target.account },
    'describe-stacks': { Stacks: [{ StackStatus: 'UPDATE_COMPLETE', Outputs: [
      { OutputKey: 'AuthStageOutput', OutputValue: 'locked' },
      { OutputKey: 'UserPoolIdOutput', OutputValue: target.poolId },
      { OutputKey: 'UserPoolClientIdOutput', OutputValue: 'otp-client' },
    ] }] },
    'describe-user-pool': { UserPool: { AdminCreateUserConfig: { AllowAdminCreateUserOnly: true } } },
    'list-user-pool-clients': { UserPoolClients: [{ ClientId: 'otp-client' }] },
    'describe-user-pool-client': { UserPoolClient: { ExplicitAuthFlows: ['ALLOW_REFRESH_TOKEN_AUTH'] } },
    'list-users': input => {
      if (input.PaginationToken) return { Users: [users[1]] };
      listPass++;
      return { Users: [users[0]], PaginationToken: 'page-2' };
    },
    'admin-set-user-password': {},
    'admin-user-global-sign-out': {},
    ...overrides,
  };
  const callAws = async (service, operation, input) => {
    calls.push({ service, operation, input });
    const response = responses[operation];
    return typeof response === 'function' ? response(input, listPass) : structuredClone(response);
  };
  return { calls, callAws };
}

const mutations = calls => calls.filter(call => call.operation.startsWith('admin-'));

test('dry run checks lock and paginates users without mutations or readiness receipt', async () => {
  const fake = fixture();
  const result = await migrate({ ...target, callAws: fake.callAws });
  assert.deepEqual(result, { dryRun: true, users: 2 });
  assert.equal(mutations(fake.calls).length, 0);
  assert.equal(fake.calls.filter(call => call.operation === 'list-users').length, 2);
});

test('migration retires passwords and sessions, preserving identity and phone attributes', async () => {
  const fake = fixture();
  const result = await migrate({ ...target, callAws: fake.callAws, apply: true });
  assert.equal(result.migrationComplete, true);
  assert.equal(result.migratedUsers, 2);
  assert.equal(result.clientId, 'otp-client');
  const writes = mutations(fake.calls);
  assert.deepEqual(writes.map(call => call.operation), [
    'admin-set-user-password', 'admin-user-global-sign-out',
    'admin-set-user-password', 'admin-user-global-sign-out',
  ]);
  const passwords = writes.filter(call => call.operation === 'admin-set-user-password');
  assert.notEqual(passwords[0].input.Password, passwords[1].input.Password);
  for (const { input } of passwords) {
    assert.match(input.Password, /^Aa1![A-Za-z0-9_-]{43}$/);
    assert.equal(input.Permanent, true);
    assert.equal(input.UserPoolId, target.poolId);
    assert.equal(JSON.stringify(result).includes(input.Password), false);
  }
  assert.equal(fake.calls.filter(call => call.operation === 'describe-stacks').length, 2);
});

for (const [name, overrides] of [
  ['wrong AWS account', { 'get-caller-identity': { Account: '000000000000' } }],
  ['active sign-up', { 'describe-user-pool': { UserPool: { AdminCreateUserConfig: { AllowAdminCreateUserOnly: false } } } }],
  ['legacy auth trigger', { 'describe-user-pool': { UserPool: {
    AdminCreateUserConfig: { AllowAdminCreateUserOnly: true }, LambdaConfig: { DefineAuthChallenge: 'legacy' },
  } } }],
  ['additional legacy client', { 'list-user-pool-clients': { UserPoolClients: [{ ClientId: 'otp-client' }, { ClientId: 'legacy' }] } }],
  ['native sign-in already active', { 'describe-user-pool-client': { UserPoolClient: { ExplicitAuthFlows: ['ALLOW_USER_AUTH', 'ALLOW_REFRESH_TOKEN_AUTH'] } } }],
  ['unexpected federated user', { 'list-users': { Users: [{ Username: 'federated', UserStatus: 'EXTERNAL_PROVIDER' }] } }],
]) {
  test(`refuses ${name} before any user changes`, async () => {
    const fake = fixture(overrides);
    await assert.rejects(migrate({ ...target, callAws: fake.callAws, apply: true }));
    assert.equal(mutations(fake.calls).length, 0);
  });
}

test('password or revocation failure prevents a completion receipt', async () => {
  const fake = fixture({ 'admin-user-global-sign-out': () => { throw new Error('test failure'); } });
  await assert.rejects(migrate({ ...target, callAws: fake.callAws, apply: true }), /test failure/);
  assert.equal(mutations(fake.calls).length, 2);
});

test('concurrent membership change prevents activation receipt', async () => {
  let reads = 0;
  const fake = fixture({ 'list-users': () => ({ Users: ++reads === 1 ? [users[0]] : users }) });
  await assert.rejects(migrate({ ...target, callAws: fake.callAws, apply: true }), /membership changed/);
});
