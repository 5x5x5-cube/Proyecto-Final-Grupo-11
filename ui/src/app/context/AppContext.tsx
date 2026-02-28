import React, { createContext, useContext, useState, ReactNode } from 'react';

type Language = 'ES' | 'EN' | 'PT';
type Currency = 'COP' | 'MXN' | 'USD';

interface AppContextType {
  language: Language;
  setLanguage: (lang: Language) => void;
  currency: Currency;
  setCurrency: (currency: Currency) => void;
  formatPrice: (priceInEur: number) => string;
}

const AppContext = createContext<AppContextType | undefined>(undefined);

export function AppProvider({ children }: { children: ReactNode }) {
  const [language, setLanguage] = useState<Language>('ES');
  const [currency, setCurrency] = useState<Currency>('COP');

  const formatPrice = (priceInEur: number) => {
    let price = priceInEur;
    let currencyCode = 'EUR';
    let locale = 'es-ES';

    switch (currency) {
      case 'COP':
        price = priceInEur * 4400;
        currencyCode = 'COP';
        locale = 'es-CO';
        break;
      case 'MXN':
        price = priceInEur * 19;
        currencyCode = 'MXN';
        locale = 'es-MX';
        break;
      case 'USD':
        price = priceInEur * 1.1;
        currencyCode = 'USD';
        locale = 'en-US';
        break;
      default:
        break;
    }

    return new Intl.NumberFormat(locale, {
      style: 'currency',
      currency: currencyCode,
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(price);
  };

  return (
    <AppContext.Provider value={{ language, setLanguage, currency, setCurrency, formatPrice }}>
      {children}
    </AppContext.Provider>
  );
}

export function useApp() {
  const context = useContext(AppContext);
  if (context === undefined) {
    throw new Error('useApp must be used within an AppProvider');
  }
  return context;
}
