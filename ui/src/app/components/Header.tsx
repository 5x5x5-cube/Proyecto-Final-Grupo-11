import React from 'react';
import { ArrowLeft } from 'lucide-react';
import { Button } from './ui/button';
import {
  DropdownMenu,
  DropdownMenuTrigger,
  DropdownMenuContent,
  DropdownMenuItem,
} from './ui/dropdown-menu';
import { useApp } from '../context/AppContext';

interface HeaderProps {
  title?: string;
  subtitle?: React.ReactNode;
  showBack?: boolean;
  onBack?: () => void;
}

export function Header({ title = 'TravelHub', subtitle, showBack = false, onBack }: HeaderProps) {
  const { language, setLanguage, currency, setCurrency } = useApp();

  return (
    <header className="bg-[#1976D2] text-white py-4 px-6 shadow-md sticky top-0 z-50">
      <div className="flex justify-between items-center">
        <div className="flex items-center gap-3">
          {showBack && (
            <Button
              variant="ghost"
              size="icon"
              onClick={onBack}
              className="text-white hover:bg-white/20 rounded-full h-12 w-12 shrink-0"
              aria-label="Volver"
            >
              <ArrowLeft size={28} />
            </Button>
          )}
          <div className="flex flex-col">
            <h1 className="text-2xl font-bold tracking-tight leading-tight">{title}</h1>
            {subtitle && <div className="text-base font-normal opacity-90">{subtitle}</div>}
          </div>
        </div>

        <div className="flex items-center gap-1">
          {/* Language Selector */}
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button 
                variant="ghost" 
                className="text-white hover:bg-white/20 h-12 px-3 font-semibold text-lg" 
                aria-label={`Idioma actual: ${language}. Tocar para cambiar.`}
              >
                {language}
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end" className="bg-white border-gray-200 shadow-xl min-w-[150px]">
              <DropdownMenuItem onClick={() => setLanguage('ES')} className="text-lg py-3 px-4 cursor-pointer hover:bg-gray-100">
                Español (ES)
              </DropdownMenuItem>
              <DropdownMenuItem onClick={() => setLanguage('EN')} className="text-lg py-3 px-4 cursor-pointer hover:bg-gray-100">
                English (EN)
              </DropdownMenuItem>
              <DropdownMenuItem onClick={() => setLanguage('PT')} className="text-lg py-3 px-4 cursor-pointer hover:bg-gray-100">
                Português (PT)
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>

          {/* Currency Selector */}
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button 
                variant="ghost" 
                className="text-white hover:bg-white/20 h-12 px-3 font-semibold text-lg" 
                aria-label={`Moneda actual: ${currency}. Tocar para cambiar.`}
              >
                {currency}
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end" className="bg-white border-gray-200 shadow-xl min-w-[150px]">
              <DropdownMenuItem onClick={() => setCurrency('COP')} className="text-lg py-3 px-4 cursor-pointer hover:bg-gray-100">
                COP ($)
              </DropdownMenuItem>
              <DropdownMenuItem onClick={() => setCurrency('MXN')} className="text-lg py-3 px-4 cursor-pointer hover:bg-gray-100">
                MXN ($)
              </DropdownMenuItem>
              <DropdownMenuItem onClick={() => setCurrency('USD')} className="text-lg py-3 px-4 cursor-pointer hover:bg-gray-100">
                USD ($)
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
      </div>
    </header>
  );
}
