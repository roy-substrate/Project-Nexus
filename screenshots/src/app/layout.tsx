import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Nexus Shield — App Store Screenshots",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body style={{ fontFamily: "-apple-system, 'SF Pro Display', 'SF Pro Text', Helvetica, Arial, sans-serif" }}>
        {children}
      </body>
    </html>
  );
}
