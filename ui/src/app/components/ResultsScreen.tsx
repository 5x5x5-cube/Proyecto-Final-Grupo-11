import { useNavigate, useLocation } from 'react-router';
import { ArrowLeft, Star, MapPin } from 'lucide-react';
import { Button } from './ui/button';
import { Card } from './ui/card';
import { Badge } from './ui/badge';
import { hotels } from '../data/hotels';
import { useApp } from '../context/AppContext';

export function ResultsScreen() {
  const navigate = useNavigate();
  const location = useLocation();
  const searchParams = location.state || {};
  const { formatPrice } = useApp();

  const handleHotelClick = (hotelId: number) => {
    navigate(`/detail/${hotelId}`, {
      state: { searchParams }
    });
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-[#1976D2] text-white py-4 px-6 shadow-md sticky top-0 z-10">
        <div className="flex items-center gap-4">
          <Button
            variant="ghost"
            size="icon"
            onClick={() => navigate('/')}
            className="text-white hover:bg-white/20 rounded-full w-12 h-12"
            aria-label="Volver a la búsqueda"
          >
            <ArrowLeft size={28} />
          </Button>
          <div>
            <h1 className="text-xl font-bold">Hoteles disponibles</h1>
            {searchParams.destination && (
              <p className="text-sm opacity-90">{searchParams.destination}</p>
            )}
          </div>
        </div>
      </div>

      {/* Results Count */}
      <div className="px-6 py-4 bg-white border-b border-gray-200">
        <p className="text-base text-[#212121]">
          Se encontraron <span className="font-bold">{hotels.length} hoteles</span>
        </p>
      </div>

      {/* Hotel List */}
      <div className="px-6 py-6 space-y-6">
        {hotels.map((hotel) => (
          <Card
            key={hotel.id}
            onClick={() => handleHotelClick(hotel.id)}
            className="overflow-hidden shadow-sm hover:shadow-lg transition-all cursor-pointer border border-gray-200 rounded-xl"
            role="article"
            aria-label={`Hotel ${hotel.name}, precio ${formatPrice(hotel.pricePerNight)} por noche`}
          >
            {/* Hotel Image */}
            <div className="relative h-56 overflow-hidden">
              <img
                src={hotel.image}
                alt={`Foto de ${hotel.name}`}
                className="w-full h-full object-cover"
              />
              {hotel.popular && (
                <Badge className="absolute top-4 right-4 bg-[#1976D2] text-white px-3 py-1.5 rounded-full text-sm font-medium">
                  Popular
                </Badge>
              )}
            </div>

            {/* Hotel Info */}
            <div className="p-5">
              <div className="flex justify-between items-start mb-3">
                <h3 className="text-xl font-bold text-[#212121]">{hotel.name}</h3>
                <div className="flex items-center gap-1.5 text-[#212121] bg-gray-100 px-2 py-1 rounded-lg">
                  <Star size={18} className="fill-yellow-500 text-yellow-500" />
                  <span className="text-base font-semibold">{hotel.rating}</span>
                </div>
              </div>

              <div className="flex items-center gap-2 text-gray-700 mb-4">
                <MapPin size={18} />
                <span className="text-base">{hotel.location}</span>
              </div>

              <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
                <div>
                  <span className="text-2xl font-bold text-[#1976D2]">{formatPrice(hotel.pricePerNight)}</span>
                  <span className="text-sm text-gray-600 ml-1">/ noche</span>
                </div>
                <Button
                  className="bg-[#1976D2] hover:bg-[#1565C0] text-white rounded-lg px-6 h-12 text-base font-medium w-full sm:w-auto shadow-sm"
                  onClick={(e) => {
                    e.stopPropagation();
                    handleHotelClick(hotel.id);
                  }}
                >
                  Ver detalles
                </Button>
              </div>
            </div>
          </Card>
        ))}
      </div>
    </div>
  );
}