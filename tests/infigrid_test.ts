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
  name: "Test data storage with aggregation",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const device1 = accounts.get('wallet_1')!;
    
    // Register device and store multiple data points
    let block = chain.mineBlock([
      Tx.contractCall('infigrid', 'register-device', [
        types.ascii("Temperature Sensor"),
        types.ascii("TEMP_SENSOR")
      ], device1.address),
      
      Tx.contractCall('infigrid', 'store-data', [
        types.principal(device1.address),
        types.ascii("temperature"),
        types.ascii("25")
      ], device1.address),
      
      Tx.contractCall('infigrid', 'store-data', [
        types.principal(device1.address),
        types.ascii("temperature"),
        types.ascii("27")
      ], device1.address)
    ]);
    
    block.receipts.map(receipt => receipt.result.expectOk());
    
    // Check aggregation
    let query = chain.callReadOnlyFn(
      'infigrid',
      'get-aggregation',
      [
        types.principal(device1.address),
        types.ascii("temperature")
      ],
      deployer.address
    );
    
    let aggregation = query.result.expectSome().expectTuple();
    assertEquals(aggregation['count'], types.uint(2));
    assertEquals(aggregation['sum'], 52);
    assertEquals(aggregation['average'], 26);
  },
});

Clarinet.test({
  name: "Test trigger creation and management",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const device1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('infigrid', 'register-device', [
        types.ascii("Temperature Sensor"),
        types.ascii("TEMP_SENSOR")
      ], device1.address),
      
      Tx.contractCall('infigrid', 'create-trigger', [
        types.principal(device1.address),
        types.uint(1),
        types.ascii("temperature"),
        types.ascii("ABOVE"),
        types.int(30),
        types.ascii("ALERT")
      ], device1.address)
    ]);
    
    block.receipts.map(receipt => receipt.result.expectOk());
    
    // Verify trigger
    let query = chain.callReadOnlyFn(
      'infigrid',
      'get-trigger',
      [
        types.principal(device1.address),
        types.uint(1)
      ],
      device1.address
    );
    
    let trigger = query.result.expectSome().expectTuple();
    assertEquals(trigger['data-type'], "temperature");
    assertEquals(trigger['condition'], "ABOVE");
    assertEquals(trigger['threshold'], 30);
    assertEquals(trigger['is-active'], true);
  },
});
