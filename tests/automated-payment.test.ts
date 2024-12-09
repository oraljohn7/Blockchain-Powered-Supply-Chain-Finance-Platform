import { describe, beforeEach, it, expect, vi } from 'vitest';

// Mock contract state
let payments: Record<number, any> = {};
let lastPaymentId = 0;

// Mock contract calls
const mockContractCall = vi.fn();

// Helper function to reset state before each test
function resetState() {
  payments = {};
  lastPaymentId = 0;
}

describe('Automated Payment Contract', () => {
  const contractOwner = 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM';
  const payer = 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM';
  const payee = 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG';
  
  beforeEach(() => {
    resetState();
    vi.resetAllMocks();
  });
  
  it('should create a payment', () => {
    mockContractCall.mockImplementation((contract, method, ...args) => {
      if (method === 'create-payment') {
        const [invoiceId, amount, payerAddress, payeeAddress] = args;
        const paymentId = ++lastPaymentId;
        payments[paymentId] = {
          invoice_id: Number(invoiceId.slice(1)),
          amount: Number(amount.slice(1)),
          payer: payerAddress,
          payee: payeeAddress,
          delivery_confirmation: false,
          status: 'pending'
        };
        return { success: true, value: `u${paymentId}` };
      } else if (method === 'get-payment') {
        const [paymentId] = args;
        const payment = payments[Number(paymentId.slice(1))];
        return { success: true, value: payment };
      }
    });
    
    const result = mockContractCall('automated-payment', 'create-payment', 'u1', 'u1000', payer, payee);
    expect(result).toEqual({ success: true, value: 'u1' });
    
    const payment = mockContractCall('automated-payment', 'get-payment', 'u1');
    expect(payment).toEqual({
      success: true,
      value: {
        invoice_id: 1,
        amount: 1000,
        payer: payer,
        payee: payee,
        delivery_confirmation: false,
        status: 'pending'
      }
    });
  });
});

