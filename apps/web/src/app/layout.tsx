import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "KiranaOS — Web Store Portal",
  description: "Next-generation retail POS and business management for Kirana stores",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="antialiased bg-slate-50 text-slate-900">
        {children}
      </body>
    </html>
  );
}
