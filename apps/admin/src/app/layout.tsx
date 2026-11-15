import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Patii Admin Panel',
  description: 'Operations and live table monitoring for Patii',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="antialiased bg-gray-50 text-gray-900">{children}</body>
    </html>
  );
}
