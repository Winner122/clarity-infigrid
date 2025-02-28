import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// [Previous tests remain unchanged...]

Clarinet.test({
  name: "Test device removal from group",
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
      ], deployer.address),
      
      Tx.contractCall('infigrid', 'remove-device-from-group', [
        types.ascii("sensor-network-1"),
        types.principal(device1.address)
      ], deployer.address)
    ]);
    
    block.receipts.map(receipt => receipt.result.expectOk());
  },
});

Clarinet.test({
  name: "Test alert severity validation",
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
        types.uint(6), // Should fail - exceeds MAX-SEVERITY
        types.ascii("Temperature threshold exceeded")
      ], deployer.address)
    ]);
    
    block.receipts[0].result.expectOk();
    block.receipts[1].result.expectErr(109); // err-invalid-severity
  },
});
