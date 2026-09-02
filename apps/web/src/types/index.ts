export interface ShopProfile {
  id: string;
  name: string;
  phone: string;
  email?: string;
  gstin?: string;
  fssaiLicense?: string;
  address?: string;
  city?: string;
  state: string;
  pincode?: string;
  upiId?: string;
  invoicePrefix: string;
}

export interface WebProduct {
  id: string;
  name: string;
  categoryName: string;
  unit: string;
  sellingPricePaise: number;
  mrpPaise: number;
  costPricePaise: number;
  taxRate: number;
  currentStock: number;
  minStockThreshold: number;
  hsnCode?: string;
  barcode?: string;
  isActive: boolean;
}

export interface WebCustomer {
  id: string;
  name: string;
  phone: string;
  email?: string;
  address?: string;
  creditLimitPaise: number;
  currentBalancePaise: number;
  loyaltyPoints: number;
  lastActive?: string;
}

export interface WebSupplier {
  id: string;
  name: string;
  contactPerson?: string;
  phone: string;
  email?: string;
  gstin?: string;
  pendingBalancePaise: number;
}

export interface WebPurchaseOrder {
  id: string;
  invoiceNumber: string;
  supplierName: string;
  purchaseDate: string;
  totalPaise: number;
  status: "draft" | "ordered" | "received" | "cancelled";
  itemCount: number;
}

export interface DayEndZReport {
  shiftId: string;
  registerName: string;
  cashierName: string;
  openedAt: string;
  closedAt: string;
  openingCashPaise: number;
  actualCashPaise: number;
  expectedCashPaise: number;
  variancePaise: number;
  grossSalesPaise: number;
  cashSalesPaise: number;
  upiSalesPaise: number;
  creditSalesPaise: number;
  billsCount: number;
  isBalanced: boolean;
}
