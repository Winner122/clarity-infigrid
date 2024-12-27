import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure device registration works",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const device1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('infigrid', 'register-device', [
        types.ascii("Temperature Sensor"),
        types.ascii("TEMP_SENSOR")
      ], device1.address)
    ]);
    
    block.receipts[0].result.expectOk();
    
    // Verify device info
    let query = chain.callReadOnlyFn(
      'infigrid',
      'get-device-info',
      [types.principal(device1.address)],
      deployer.address
    );
    
    let deviceInfo = query.result.expectSome().expectTuple();
    assertEquals(deviceInfo['name'], "Temperature Sensor");
    assertEquals(deviceInfo['device-type'], "TEMP_SENSOR");
    assertEquals(deviceInfo['is-active'], true);
  },
});

Clarinet.test({
  name: "Test data storage and permissions",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const device1 = accounts.get('wallet_1')!;
    const operator = accounts.get('wallet_2')!;
    
    // Register device
    let block = chain.mineBlock([
      Tx.contractCall('infigrid', 'register-device', [
        types.ascii("Temperature Sensor"),
        types.ascii("TEMP_SENSOR")
      ], device1.address),
      
      // Set permissions for operator
      Tx.contractCall('infigrid', 'set-device-permission', [
        types.principal(device1.address),
        types.principal(operator.address),
        types.bool(true),
        types.bool(true)
      ], device1.address)
    ]);
    
    block.receipts.map(receipt => receipt.result.expectOk());
    
    // Store data using operator account
    let dataBlock = chain.mineBlock([
      Tx.contractCall('infigrid', 'store-data', [
        types.principal(device1.address),
        types.ascii("temperature"),
        types.ascii("25.5")
      ], operator.address)
    ]);
    
    dataBlock.receipts[0].result.expectOk();
    
    // Verify stored data
    let timestamp = dataBlock.receipts[0].result.expectOk().expectUint();
    let query = chain.callReadOnlyFn(
      'infigrid',
      'get-device-data',
      [
        types.principal(device1.address),
        types.uint(timestamp)
      ],
      deployer.address
    );
    
    let data = query.result.expectSome().expectTuple();
    assertEquals(data['data-type'], "temperature");
    assertEquals(data['value'], "25.5");
    assertEquals(data['verified'], true);
  },
});

Clarinet.test({
  name: "Test unauthorized access prevention",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const device1 = accounts.get('wallet_1')!;
    const unauthorized = accounts.get('wallet_2')!;
    
    // Register device
    let block = chain.mineBlock([
      Tx.contractCall('infigrid', 'register-device', [
        types.ascii("Temperature Sensor"),
        types.ascii("TEMP_SENSOR")
      ], device1.address),
      
      // Attempt unauthorized data storage
      Tx.contractCall('infigrid', 'store-data', [
        types.principal(device1.address),
        types.ascii("temperature"),
        types.ascii("25.5")
      ], unauthorized.address)
    ]);
    
    block.receipts[0].result.expectOk();
    block.receipts[1].result.expectErr(types.uint(100)); // err-not-authorized
  },
});