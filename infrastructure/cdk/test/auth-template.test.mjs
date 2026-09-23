import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

// Synthesize both stages first. These checks inspect emitted CloudFormation,
// including L2 defaults that can accidentally re-enable legacy authentication.
const directory = process.env.AUTH_TEMPLATE_DIR ?? fileURLToPath(new URL('../cdk.out/', import.meta.url));
const template = JSON.parse(readFileSync(join(directory, 'FinpalFoundation.template.json')));
const resources = template.Resources;
const stage = template.Outputs.AuthStageOutput.Value;
const pool = resources.UserPoolPhone8BB2D86D;
const client = resources.MobileOtpClientA723F0FA;

test('retains the existing pool identity, schema and phone verification requirements', () => {
  assert.equal(pool.Type, 'AWS::Cognito::UserPool');
  assert.equal(pool.DeletionPolicy, 'Retain');
  assert.deepEqual(pool.Properties.UsernameAttributes, ['phone_number']);
  assert.deepEqual(pool.Properties.Schema, [{ Mutable: true, Name: 'phone_number', Required: true }]);
  assert.equal(pool.Properties.UserPoolTier, 'ESSENTIALS');
  assert.deepEqual(pool.Properties.Policies.SignInPolicy.AllowedFirstAuthFactors, ['PASSWORD', 'SMS_OTP']);
  assert.deepEqual(pool.Properties.UserAttributeUpdateSettings.AttributesRequireVerificationBeforeUpdate, ['phone_number']);
  assert.equal(pool.Properties.LambdaConfig, undefined);
  assert.equal(pool.Properties.SmsConfiguration.SnsRegion, 'ap-south-1');
});

test('deletes the legacy app client and accepts tokens only from its replacement', () => {
  assert.equal(Object.keys(resources).some(key => key.startsWith('MobileAppClientV2')), false);
  assert.equal(Object.values(resources).filter(item => item.Type === 'AWS::Cognito::UserPoolClient').length, 1);
  assert.equal(client.Properties.GenerateSecret, false);
  assert.equal(client.Properties.AllowedOAuthFlowsUserPoolClient, false);
  assert.deepEqual(client.Properties.WriteAttributes, ['phone_number']);
  const authorizer = Object.values(resources).find(item => item.Type === 'AWS::ApiGatewayV2::Authorizer');
  assert.deepEqual(authorizer.Properties.JwtConfiguration.Audience, [{ Ref: 'MobileOtpClientA723F0FA' }]);
});

test('only an activated migration permits signup and native sign-in', () => {
  assert.ok(['locked', 'otp'].includes(stage));
  assert.equal(pool.Properties.AdminCreateUserConfig.AllowAdminCreateUserOnly, stage === 'locked');
  assert.deepEqual(client.Properties.ExplicitAuthFlows, stage === 'locked'
    ? ['ALLOW_REFRESH_TOKEN_AUTH'] : ['ALLOW_USER_AUTH', 'ALLOW_REFRESH_TOKEN_AUTH']);
  assert.equal(client.Properties.EnableTokenRevocation, true);
});

test('auth migration introduces no bypass Lambdas or prohibited infrastructure', () => {
  for (const [id, resource] of Object.entries(resources)) {
    assert.equal(/PreSignUpFn|DefineAuthChallengeFn/.test(id), false);
    assert.equal(/OpenSearch|Elasticsearch|AOSS/.test(resource.Type), false);
    assert.equal(resource.Properties?.SnapStart, undefined);
  }
});
