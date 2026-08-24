export interface ShopSummary {
  id: string;
  name: string;
  phone: string;
  gstin?: string;
  todaySalesPaise: number;
  activeBillsCount: number;
}

export interface WebProduct {
  id: string;
  name: string;
  barcode: string;
  sellingPricePaise: number;
  mrpPaise: number;
  currentStock: number;
  categoryName?: string;
}

export interface WebUdhaarCustomer {
  id: string;
  name: string;
  phone: string;
  debtPaise: number;
  creditLimitPaise: number;
}
