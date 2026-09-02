export interface ProductItem {
  id: string;
  name: string;
  category: string;
  barcode: string;
  mrp: number;
  salePrice: number;
  costPrice: number;
  currentStock: number;
  minStock: number;
  unit: string;
  hsn: string;
  gstRate: number; // 0, 5, 12, 18
  shelfLocation: string;
}

export interface CustomerItem {
  id: string;
  name: string;
  phone: string;
  address: string;
  khataBalance: number;
  creditLimit: number;
  status: "clear" | "normal" | "overdue";
  lastPaymentDate: string;
  overdueDays: number;
}

export interface SupplierItem {
  id: string;
  name: string;
  contactPerson: string;
  phone: string;
  gstin: string;
  category: string;
  outstandingBalance: number;
  lastDeliveryDate: string;
}

export interface ShopProfile {
  id: string;
  name: string;
  owner: string;
  phone: string;
  email: string;
  address: string;
  gstin: string;
  upiId: string;
  thermalPrinterWidth: "58mm" | "80mm";
  cashierRegisters: number;
}

export const SEED_SHOP_PROFILE: ShopProfile = {
  id: "shop_slp_01",
  name: "Sri Lakshmi Provision & Supermarket",
  owner: "Ramesh Kumar",
  phone: "9845012345",
  email: "srilakshmi.kirana@gmail.com",
  address: "14/2, 8th Main, 4th Block, Jayanagar, Bengaluru - 560011",
  gstin: "29AAAAA0000A1Z5",
  upiId: "srilakshmi.kirana@okaxis",
  thermalPrinterWidth: "80mm",
  cashierRegisters: 2,
};

export const SEED_PRODUCTS: ProductItem[] = [
  {
    id: "prod_01",
    name: "Amul Pasteurised Butter 500g",
    category: "Dairy & Eggs",
    barcode: "8901262010114",
    mrp: 275.0,
    salePrice: 260.0,
    costPrice: 235.0,
    currentStock: 7,
    minStock: 8,
    unit: "packet",
    hsn: "04051000",
    gstRate: 12,
    shelfLocation: "Shelf A3",
  },
  {
    id: "prod_02",
    name: "Brooke Bond Red Label Tea 500g",
    category: "Beverages",
    barcode: "8901030383132",
    mrp: 320.0,
    salePrice: 295.0,
    costPrice: 260.0,
    currentStock: 3,
    minStock: 10,
    unit: "packet",
    hsn: "09024020",
    gstRate: 5,
    shelfLocation: "Shelf B1",
  },
  {
    id: "prod_03",
    name: "Aashirvaad Superior MP Shudh Chakki Atta 10kg",
    category: "Grains & Flours",
    barcode: "8901725121404",
    mrp: 495.0,
    salePrice: 460.0,
    costPrice: 420.0,
    currentStock: 2,
    minStock: 5,
    unit: "bag",
    hsn: "11010000",
    gstRate: 5,
    shelfLocation: "Pallet Stack C",
  },
  {
    id: "prod_04",
    name: "Tata Salt Vacuum Evaporated Iodised 1kg",
    category: "Cooking Essentials",
    barcode: "8901058852108",
    mrp: 28.0,
    salePrice: 25.0,
    costPrice: 21.0,
    currentStock: 24,
    minStock: 10,
    unit: "packet",
    hsn: "25010010",
    gstRate: 0,
    shelfLocation: "Shelf A1",
  },
  {
    id: "prod_05",
    name: "Fortune Sunlite Refined Sunflower Oil 1L Pouch",
    category: "Cooking Essentials",
    barcode: "8906007280014",
    mrp: 145.0,
    salePrice: 135.0,
    costPrice: 118.0,
    currentStock: 18,
    minStock: 12,
    unit: "pouch",
    hsn: "15121910",
    gstRate: 5,
    shelfLocation: "Shelf A4",
  },
  {
    id: "prod_06",
    name: "Maggi 2-Minute Masala Instant Noodles 420g (Pack of 6)",
    category: "Instant Food",
    barcode: "8901058854447",
    mrp: 96.0,
    salePrice: 90.0,
    costPrice: 78.0,
    currentStock: 15,
    minStock: 6,
    unit: "multipack",
    hsn: "19023010",
    gstRate: 18,
    shelfLocation: "Shelf D2",
  },
  {
    id: "prod_07",
    name: "Parle-G Original Gluco Biscuits 800g Family Pack",
    category: "Snacks & Biscuits",
    barcode: "8901719101016",
    mrp: 85.0,
    salePrice: 78.0,
    costPrice: 68.0,
    currentStock: 22,
    minStock: 8,
    unit: "pack",
    hsn: "19053100",
    gstRate: 18,
    shelfLocation: "Front Display",
  },
  {
    id: "prod_08",
    name: "Britannia Good Day Cashew Cookies 600g",
    category: "Snacks & Biscuits",
    barcode: "8901063012016",
    mrp: 130.0,
    salePrice: 120.0,
    costPrice: 102.0,
    currentStock: 16,
    minStock: 6,
    unit: "pack",
    hsn: "19053100",
    gstRate: 18,
    shelfLocation: "Front Display",
  },
  {
    id: "prod_09",
    name: "Dettol Original Germ Protection Bathing Soap 125g (Pack of 4)",
    category: "Personal Care",
    barcode: "8901396316016",
    mrp: 198.0,
    salePrice: 185.0,
    costPrice: 155.0,
    currentStock: 12,
    minStock: 5,
    unit: "multipack",
    hsn: "34011110",
    gstRate: 18,
    shelfLocation: "Shelf E1",
  },
  {
    id: "prod_10",
    name: "Ariel Matic Top Load Detergent Powder 2kg",
    category: "Household & Cleaning",
    barcode: "4902430732802",
    mrp: 460.0,
    salePrice: 425.0,
    costPrice: 360.0,
    currentStock: 6,
    minStock: 4,
    unit: "bag",
    hsn: "34022010",
    gstRate: 18,
    shelfLocation: "Bottom Rack E",
  },
];

export const SEED_CUSTOMERS: CustomerItem[] = [
  {
    id: "cust_01",
    name: "Sunita Patel",
    phone: "9845011223",
    address: "Flat 204, Gardenia Apts, 8th Main",
    khataBalance: 8200.0,
    creditLimit: 10000.0,
    status: "overdue",
    lastPaymentDate: "2026-08-15",
    overdueDays: 18,
  },
  {
    id: "cust_02",
    name: "Rajesh Gowda",
    phone: "9845033445",
    address: "#45, 3rd Cross, Jayanagar",
    khataBalance: 4500.0,
    creditLimit: 8000.0,
    status: "normal",
    lastPaymentDate: "2026-08-28",
    overdueDays: 5,
  },
  {
    id: "cust_03",
    name: "Suresh Raina",
    phone: "9845055667",
    address: "#12, Kanakapura Road",
    khataBalance: 2450.0,
    creditLimit: 5000.0,
    status: "overdue",
    lastPaymentDate: "2026-08-18",
    overdueDays: 14,
  },
  {
    id: "cust_04",
    name: "Anita Sharma",
    phone: "9845077889",
    address: "#88, Rose Villa, 4th Block",
    khataBalance: 3350.0,
    creditLimit: 6000.0,
    status: "normal",
    lastPaymentDate: "2026-08-30",
    overdueDays: 3,
  },
  {
    id: "cust_05",
    name: "Deepak Chawla",
    phone: "9845099001",
    address: "Shop 4, Market Road",
    khataBalance: 0.0,
    creditLimit: 5000.0,
    status: "clear",
    lastPaymentDate: "2026-09-01",
    overdueDays: 0,
  },
];

export const SEED_SUPPLIERS: SupplierItem[] = [
  {
    id: "sup_01",
    name: "Bangalore FMCG Wholesalers Ltd",
    contactPerson: "Nagaraj Rao",
    phone: "9844012345",
    gstin: "29BBBBB1111B1Z2",
    category: "Packaged Foods & Staples",
    outstandingBalance: 38500.0,
    lastDeliveryDate: "2026-08-29",
  },
  {
    id: "sup_02",
    name: "Amul Dairy Cold-Chain Depot",
    contactPerson: "Santosh Naik",
    phone: "9844023456",
    gstin: "29CCCCC2222C1Z3",
    category: "Dairy & Butter",
    outstandingBalance: 14200.0,
    lastDeliveryDate: "2026-09-01",
  },
  {
    id: "sup_03",
    name: "Hindustan Unilever Distribution",
    contactPerson: "Karthik Swaminathan",
    phone: "9844034567",
    gstin: "29DDDDD3333D1Z4",
    category: "Personal Care & Homecare",
    outstandingBalance: 24000.0,
    lastDeliveryDate: "2026-08-27",
  },
];
