import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// [Previous test implementations remain unchanged]

Clarinet.test({
  name: "Test device group creation and management",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const device1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('infigrid', 'create-device-group', [
        types.ascii("sensor-network-1"),
        types.ascii("Temperature sensors in Building A"),
        types.uint(3)
      ], deployer.address),
      
      Tx.contractCall('infigrid', 'add-device-to-group', [
        types.ascii("sensor-network-1"),
        types.principal(device1.address)
      ], deployer.address)
    ]);
    
    block.receipts.map(receipt => receipt.result.expectOk());
    
    let query = chain.callReadOnlyFn(
      'infigrid',
      'get-device-group',
      [types.ascii("sensor-network-1")],
      deployer.address
    );
    
    let groupInfo = query.result.expectSome().expectTuple();
    assertEquals(groupInfo['description'], "Temperature sensors in Building A");
    assertEquals(groupInfo['alert-threshold'], types.uint(3));
  },
});

Clarinet.test({
  name: "Test group alert creation and resolution",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('infigrid', 'create-device-group', [
        types.ascii("sensor-network-1"),
        types.ascii("Temperature sensors in Building A"),
        types.uint(3)
      ], deployer.address),
      
      Tx.contractCall('infigrid', 'create-group-alert', [
        types.ascii("sensor-network-1"),
        types.uint(1),
        types.ascii("HIGH_TEMP"),
        types.uint(2),
        types.ascii("Temperature threshold exceeded in multiple sensors")
      ], deployer.address)
    ]);
    
    block.receipts.map(receipt => receipt.result.expectOk());
    
    let query = chain.callReadOnlyFn(
      'infigrid',
      'get-group-alert',
      [
        types.ascii("sensor-network-1"),
        types.uint(1)
      ],
      deployer.address
    );
    
    let alertInfo = query.result.expectSome().expectTuple();
    assertEquals(alertInfo['alert-type'], "HIGH_TEMP");
    assertEquals(alertInfo['resolved'], false);
    
    // Test alert resolution
    block = chain.mineBlock([
      Tx.contractCall('infigrid', 'resolve-group-alert', [
        types.ascii("sensor-network-1"),
        types.uint(1)
      ], deployer.address)
    ]);
    
    block.receipts[0].result.expectOk();
    
    query = chain.callReadOnlyFn(
      'infigrid',
      'get-group-alert',
      [
        types.ascii("sensor-network-1"),
        types.uint(1)
      ],
      deployer.address
    );
    
    alertInfo = query.result.expectSome().expectTuple();
    assertEquals(alertInfo['resolved'], true);
  },
});
