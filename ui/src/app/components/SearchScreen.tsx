import { useState } from 'react';
import { useNavigate } from 'react-router';
import { Search, MapPin, Calendar, Users } from 'lucide-react';
import { Input } from './ui/input';
import { Button } from './ui/button';
import { Label } from './ui/label';
import { HeaderControls } from './HeaderControls';

export function SearchScreen() {
  const navigate = useNavigate();
  const [destination, setDestination] = useState('');
  const [checkIn, setCheckIn] = useState('');
  const [checkOut, setCheckOut] = useState('');
  const [guests, setGuests] = useState('2');

  const handleSearch = () => {
    if (destination && checkIn && checkOut) {
      navigate('/results', {
        state: { destination, checkIn, checkOut, guests }
      });
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-[#1976D2] text-white py-6 px-6 shadow-md flex justify-between items-start">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">TravelHub</h1>
          <p className="text-base opacity-90 mt-1">Encuentra tu hotel ideal</p>
        </div>
        <HeaderControls />
      </div>

      {/* Search Form */}
      <div className="px-6 py-8">
        <div className="max-w-md mx-auto bg-white p-6 rounded-xl shadow-sm border border-gray-100">
          <h2 className="text-2xl font-semibold text-[#212121] mb-6">Buscar hoteles</h2>

          {/* Destination */}
          <div className="mb-6">
            <Label htmlFor="destination" className="text-[#424242] text-base mb-2 block font-medium">
              Destino
            </Label>
            <div className="relative">
              <MapPin className="absolute left-4 top-1/2 transform -translate-y-1/2 text-gray-500" size={24} />
              <Input
                id="destination"
                type="text"
                placeholder="¿A dónde vas?"
                value={destination}
                onChange={(e) => setDestination(e.target.value)}
                className="pl-12 h-14 text-lg rounded-lg border-gray-300 focus:border-[#1976D2] focus:ring-[#1976D2]"
              />
            </div>
          </div>

          {/* Check-in Date */}
          <div className="mb-6">
            <Label htmlFor="checkin" className="text-[#424242] text-base mb-2 block font-medium">
              Fecha de entrada
            </Label>
            <div className="relative">
              <Calendar className="absolute left-4 top-1/2 transform -translate-y-1/2 text-gray-500" size={24} />
              <Input
                id="checkin"
                type="date"
                value={checkIn}
                onChange={(e) => setCheckIn(e.target.value)}
                className="pl-12 h-14 text-lg rounded-lg border-gray-300 focus:border-[#1976D2] focus:ring-[#1976D2]"
              />
            </div>
          </div>

          {/* Check-out Date */}
          <div className="mb-6">
            <Label htmlFor="checkout" className="text-[#424242] text-base mb-2 block font-medium">
              Fecha de salida
            </Label>
            <div className="relative">
              <Calendar className="absolute left-4 top-1/2 transform -translate-y-1/2 text-gray-500" size={24} />
              <Input
                id="checkout"
                type="date"
                value={checkOut}
                onChange={(e) => setCheckOut(e.target.value)}
                className="pl-12 h-14 text-lg rounded-lg border-gray-300 focus:border-[#1976D2] focus:ring-[#1976D2]"
              />
            </div>
          </div>

          {/* Guests */}
          <div className="mb-8">
            <Label htmlFor="guests" className="text-[#424242] text-base mb-2 block font-medium">
              Cantidad de personas
            </Label>
            <div className="relative">
              <Users className="absolute left-4 top-1/2 transform -translate-y-1/2 text-gray-500" size={24} />
              <Input
                id="guests"
                type="number"
                min="1"
                max="10"
                value={guests}
                onChange={(e) => setGuests(e.target.value)}
                className="pl-12 h-14 text-lg rounded-lg border-gray-300 focus:border-[#1976D2] focus:ring-[#1976D2]"
              />
            </div>
          </div>

          {/* Search Button */}
          <Button
            onClick={handleSearch}
            className="w-full h-16 bg-[#1976D2] hover:bg-[#1565C0] text-white rounded-lg text-xl font-medium shadow-md transition-transform active:scale-[0.98]"
          >
            <Search size={24} className="mr-2" />
            Buscar
          </Button>
        </div>
      </div>

      {/* Popular Destinations */}
      <div className="px-6 pb-12">
        <div className="max-w-md mx-auto">
          <h3 className="text-xl font-semibold text-[#212121] mb-4">Destinos populares</h3>
          <div className="grid grid-cols-2 gap-4">
            {['Barcelona', 'Madrid', 'Valencia', 'Sevilla'].map((city) => (
              <button
                key={city}
                onClick={() => setDestination(city)}
                className="py-4 px-4 border border-gray-300 rounded-lg text-[#424242] text-lg font-medium bg-white hover:border-[#1976D2] hover:text-[#1976D2] hover:bg-blue-50 transition-colors shadow-sm"
              >
                {city}
              </button>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
