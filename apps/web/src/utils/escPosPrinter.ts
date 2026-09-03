"use client";

/**
 * Raw ESC/POS Thermal Printer Driver & Byte Stream Generator
 * Supports direct raw printing over Web Serial API and Web Bluetooth API.
 */

export interface EscPosPrintOptions {
  paperWidth: "58mm" | "80mm";
  storeName?: string;
  address?: string;
  gstin?: string;
  phone?: string;
  invoiceNumber: string;
  dateStr: string;
  cashierName: string;
  items: Array<{ name: string; qty: number; rate: number; total: number }>;
  subtotal: number;
  tax: number;
  total: number;
  paymentMode: string;
}

export class EscPosPrinterDriver {
  private static readonly ESC = 0x1b;
  private static readonly GS = 0x1d;

  /**
   * Generates a Uint8Array containing standard raw ESC/POS binary command sequences.
   */
  public static generateReceiptBytes(options: EscPosPrintOptions): Uint8Array {
    const is58mm = options.paperWidth === "58mm";
    const lineCharWidth = is58mm ? 32 : 48;
    const encoder = new TextEncoder();
    const chunks: number[] = [];

    const pushBytes = (...bytes: number[]) => {
      chunks.push(...bytes);
    };

    const pushText = (text: string) => {
      const encoded = encoder.encode(text);
      for (let i = 0; i < encoded.length; i++) {
        chunks.push(encoded[i]);
      }
    };

    const pushLine = (text: string = "") => {
      pushText(text + "\n");
    };

    const divider = (char: string = "-") => {
      pushLine(char.repeat(lineCharWidth));
    };

    // 1. Initialize Printer (ESC @)
    pushBytes(this.ESC, 0x40);

    // 2. Header (Centered, Bold)
    pushBytes(this.ESC, 0x61, 0x01); // Center Align
    pushBytes(this.ESC, 0x45, 0x01); // Bold ON
    pushBytes(this.GS, 0x21, 0x11); // Double width & height
    pushLine(options.storeName || "SRI LAKSHMI PROVISION");
    pushBytes(this.GS, 0x21, 0x00); // Normal size
    pushBytes(this.ESC, 0x45, 0x00); // Bold OFF

    pushLine(options.address || "Indiranagar, Bengaluru - 560038");
    pushLine(`GSTIN: ${options.gstin || "29AAAAA0000A1Z5"}`);
    pushLine(`Ph: ${options.phone || "9845012345"}`);
    divider("=");

    // 3. Invoice Meta (Left Align)
    pushBytes(this.ESC, 0x61, 0x00); // Left Align
    pushLine(`Invoice: ${options.invoiceNumber}`);
    pushLine(`Date:    ${options.dateStr}`);
    pushLine(`Cashier: ${options.cashierName}`);
    pushLine(`Payment: ${options.paymentMode.toUpperCase()}`);
    divider("-");

    // 4. Items Table Header
    if (is58mm) {
      // 32 chars: Item(16) Qty(4) Rate(5) Total(7)
      pushBytes(this.ESC, 0x45, 0x01);
      pushLine("ITEM             QTY  RATE   TOTAL");
      pushBytes(this.ESC, 0x45, 0x00);
      divider("-");

      options.items.forEach((it) => {
        const namePart = it.name.substring(0, 15).padEnd(16, " ");
        const qtyPart = String(it.qty).padStart(4, " ");
        const ratePart = String(Math.round(it.rate)).padStart(5, " ");
        const totalPart = String(Math.round(it.total)).padStart(7, " ");
        pushLine(`${namePart}${qtyPart}${ratePart}${totalPart}`);
      });
    } else {
      // 48 chars layout
      pushBytes(this.ESC, 0x45, 0x01);
      pushLine("ITEM NAME                  QTY   RATE      TOTAL");
      pushBytes(this.ESC, 0x45, 0x00);
      divider("-");

      options.items.forEach((it) => {
        const namePart = it.name.substring(0, 24).padEnd(25, " ");
        const qtyPart = String(it.qty).padStart(5, " ");
        const ratePart = String(it.rate.toFixed(2)).padStart(8, " ");
        const totalPart = String(it.total.toFixed(2)).padStart(10, " ");
        pushLine(`${namePart}${qtyPart}${ratePart}${totalPart}`);
      });
    }
    divider("-");

    // 5. Totals (Right Align)
    pushBytes(this.ESC, 0x61, 0x02); // Right Align
    pushLine(`Subtotal:  INR ${options.subtotal.toFixed(2)}`);
    pushLine(`GST (5%):  INR ${options.tax.toFixed(2)}`);
    pushBytes(this.ESC, 0x45, 0x01);
    pushLine(`NET TOTAL: INR ${options.total.toFixed(2)}`);
    pushBytes(this.ESC, 0x45, 0x00);
    divider("=");

    // 6. Footer (Center)
    pushBytes(this.ESC, 0x61, 0x01);
    pushLine("** THANK YOU! VISIT AGAIN **");
    pushLine("Goods once sold can be exchanged in 48 hrs.");
    pushLine("Powered by KiranaOS Retail ERP");

    // 7. Feed 4 lines & Cut paper (GS V B 0)
    pushBytes(0x0a, 0x0a, 0x0a, 0x0a);
    pushBytes(this.GS, 0x56, 0x42, 0x00);

    return new Uint8Array(chunks);
  }

  /**
   * Direct printing via Web Serial API (USB ESC/POS Printer)
   */
  public static async printViaWebSerial(data: Uint8Array): Promise<{ success: boolean; message: string }> {
    if (typeof navigator === "undefined" || !("serial" in navigator)) {
      return {
        success: false,
        message: "Web Serial API is not supported in this browser. Please use Chrome or Edge.",
      };
    }

    try {
      const serial = (navigator as unknown as { serial: any }).serial;
      const port = await serial.requestPort();
      await port.open({ baudRate: 9600 });

      const writer = port.writable.getWriter();
      await writer.write(data);
      writer.releaseLock();
      await port.close();

      return { success: true, message: "Receipt dispatched directly to USB Thermal Printer!" };
    } catch (err: any) {
      if (err.name === "NotFoundError") {
        return { success: false, message: "No printer device selected." };
      }
      return { success: false, message: err.message || "Failed to communicate with serial printer." };
    }
  }

  /**
   * Direct printing via Web Bluetooth API (Wireless 58mm/80mm Mini-Printer)
   */
  public static async printViaBluetooth(data: Uint8Array): Promise<{ success: boolean; message: string }> {
    if (typeof navigator === "undefined" || !("bluetooth" in navigator)) {
      return {
        success: false,
        message: "Web Bluetooth API is not supported in this browser. Please use Chrome or Edge.",
      };
    }

    try {
      const bluetooth = (navigator as unknown as { bluetooth: any }).bluetooth;
      const device = await bluetooth.requestDevice({
        acceptAllDevices: true,
        optionalServices: ["000018f0-0000-1000-8000-00805f9b34fb", "e7810a71-73ae-499d-8c15-faa9aef0c3f2"],
      });

      const server = await device.gatt.connect();
      // Attempt generic serial/printer service
      const services = await server.getPrimaryServices();
      if (services.length === 0) {
        return { success: false, message: "No compatible Bluetooth printer service found." };
      }

      const characteristic = (await services[0].getCharacteristics())[0];
      await characteristic.writeValue(data);
      await server.disconnect();

      return { success: true, message: "Receipt dispatched directly to Bluetooth Mini-Printer!" };
    } catch (err: any) {
      if (err.name === "NotFoundError") {
        return { success: false, message: "Bluetooth pairing cancelled." };
      }
      return { success: false, message: err.message || "Bluetooth printer communication error." };
    }
  }
}
