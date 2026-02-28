import { Globe, DollarSign, Check } from 'lucide-react';
import { Button } from './ui/button';
import {
  DropdownMenu,
  DropdownMenuTrigger,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuGroup
} from './ui/dropdown-menu';
import { useApp } from '../context/AppContext';

export function HeaderControls() {
  const { language, setLanguage, currency, setCurrency } = useApp();

  return (
    <div className="flex items-center gap-1">
      {/* Language Selector */}
      <DropdownMenu>
        <DropdownMenuTrigger className="inline-flex items-center justify-center whitespace-nowrap rounded-full w-12 h-12 text-sm font-medium transition-all outline-none focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px] disabled:pointer-events-none disabled:opacity-50 text-white hover:bg-white/20">
            <Globe className="h-6 w-6" />
            <span className="sr-only">Cambiar idioma, actual: {language}</span>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end" className="w-40 bg-white border-gray-200">
          <DropdownMenuLabel>Idioma</DropdownMenuLabel>
          <DropdownMenuSeparator />
          <DropdownMenuGroup>
            {(['ES', 'EN', 'PT'] as const).map((lang) => (
              <DropdownMenuItem
                key={lang}
                className="justify-between cursor-pointer focus:bg-gray-100"
                onClick={() => setLanguage(lang)}
              >
                <span>{lang}</span>
                {language === lang && <Check className="h-4 w-4 text-[#1976D2]" />}
              </DropdownMenuItem>
            ))}
          </DropdownMenuGroup>
        </DropdownMenuContent>
      </DropdownMenu>

      {/* Currency Selector */}
      <DropdownMenu>
        <DropdownMenuTrigger className="inline-flex items-center justify-center whitespace-nowrap rounded-full w-12 h-12 text-sm font-medium transition-all outline-none focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px] disabled:pointer-events-none disabled:opacity-50 text-white hover:bg-white/20">
            <DollarSign className="h-6 w-6" />
            <span className="sr-only">Cambiar moneda, actual: {currency}</span>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end" className="w-40 bg-white border-gray-200">
          <DropdownMenuLabel>Moneda</DropdownMenuLabel>
          <DropdownMenuSeparator />
          <DropdownMenuGroup>
            {(['COP', 'MXN', 'USD'] as const).map((curr) => (
              <DropdownMenuItem
                key={curr}
                className="justify-between cursor-pointer focus:bg-gray-100"
                onClick={() => setCurrency(curr)}
              >
                <span>{curr}</span>
                {currency === curr && <Check className="h-4 w-4 text-[#1976D2]" />}
              </DropdownMenuItem>
            ))}
          </DropdownMenuGroup>
        </DropdownMenuContent>
      </DropdownMenu>
    </div>
  );
}
