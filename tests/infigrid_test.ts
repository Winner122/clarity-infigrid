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
  name: "Test device removal from group - success and failure cases",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const device1 = accounts.get('wallet_1')!;
    const device2 = accounts.get('wallet_2')!;
    
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
      
      // Try removing non-existent device
      Tx.contractCall('infigrid', 'remove-device-from-group', [
        types.ascii("sensor-network-1"),
        types.principal(device2.address)
      ], deployer.address),
      
      // Remove existing device
      Tx.contractCall('infigrid', 'remove-device-from-group', [
        types.ascii("sensor-network-1"),
        types.principal(device1.address)
      ], deployer.address)
    ]);
    
    block.receipts[0].result.expectOk();
    block.receipts[1].result.expectOk();
    block.receipts[2].result.expectErr(110); // err-device-not-in-group
    block.receipts[3].result.expectOk();
  },
});

// [Rest of the tests remain unchanged...]
