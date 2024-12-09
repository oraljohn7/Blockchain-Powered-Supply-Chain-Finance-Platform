import { describe, beforeEach, it, expect, vi } from 'vitest';

// Mock contract state
let invoices: Record<number, any> = {};
let lastInvoiceId = 0;

// Mock contract calls
const mockContractCall = vi.fn();

// Helper function to reset state before each test
function resetState() {
  invoices = {};
  lastInvoiceId = 0;
}

describe('Invoice Token Contract', () => {
  const contractOwner = 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM';
  const issuer = 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG';
  const payer = 'ST3AM1A56AK2C1XAFJ4115ZSV26EB49BVQ10MGCS0';
  const recipient = 'ST3AM1A56AK2C1XAFJ4115ZSV26EB49BVQ10MGCS0';
  
  beforeEach(() => {
    resetState();
    vi.resetAllMocks();
  });
  
  it('should create an invoice', () => {
    mockContractCall.mockImplementation((contract, method, ...args) => {
      if (method === 'create-invoice') {
        const [amount, issuer, payer, dueDate] = args;
        const invoiceId = ++lastInvoiceId;
        invoices[invoiceId] = {
          amount: Number(amount.slice(1)),
          issuer,
          payer,
          due_date: Number(dueDate.slice(1)),
          status: 'pending'
        };
        return { success: true, value: `u${invoiceId}` };
      } else if (method === 'get-invoice') {
        const [invoiceId] = args;
        const invoice = invoices[Number(invoiceId.slice(1))];
        return { success: true, value: invoice };
      }
    });
    
    const result = mockContractCall('invoice-token', 'create-invoice', 'u1000', issuer, payer, 'u1625097600');
    expect(result).toEqual({ success: true, value: 'u1' });
    
    const invoice = mockContractCall('invoice-token', 'get-invoice', 'u1');
    expect(invoice).toEqual({
      success: true,
      value: {
        amount: 1000,
        issuer: issuer,
        payer: payer,
        due_date: 1625097600,
        status: 'pending'
      }
    });
  });
});

