import { useNavigate, useLocation, useParams } from 'react-router';
import { ArrowLeft, MapPin, Wifi, Coffee, Car, Star, Clock } from 'lucide-react';
import { QRCodeSVG } from 'qrcode.react';
import { Button } from './ui/button';
import { Card } from './ui/card';
import { Alert, AlertDescription } from './ui/alert';
import { hotels } from '../data/hotels';
import { useApp } from '../context/AppContext';

export function DetailScreen() {
  const navigate = useNavigate();
  const location = useLocation();
  const { hotelId } = useParams();
  const { searchParams } = location.state || {};
  const { formatPrice } = useApp();

  // Find hotel by ID from URL parameter
  const hotel = hotels.find(h => h.id === Number(hotelId));

  // If hotel not found, redirect to results
  if (!hotel) {
    navigate('/results');
    return null;
  }

  const amenities = [
    { icon: Wifi, label: 'WiFi gratuito' },
    { icon: Coffee, label: 'Desayuno incluido' },
    { icon: Car, label: 'Estacionamiento' }
  ];

  // Generate QR code data with reservation details
  const qrData = JSON.stringify({
    hotel: hotel.name,
    hotelId: hotel.id,
    checkIn: searchParams?.checkIn,
    checkOut: searchParams?.checkOut,
    guests: searchParams?.guests,
    confirmationCode: `TH-${Math.random().toString(36).substr(2, 9).toUpperCase()}`
  });

  return (
    <div className="min-h-screen bg-gray-50 pb-32">
      {/* Header */}
      <div className="bg-[#1976D2] text-white py-4 px-6 shadow-md sticky top-0 z-10">
        <div className="flex items-center gap-4">
          <Button
            variant="ghost"
            size="icon"
            onClick={() => navigate('/results')}
            className="text-white hover:bg-white/20 rounded-full w-12 h-12"
            aria-label="Volver a los resultados"
          >
            <ArrowLeft size={28} />
          </Button>
          <h1 className="text-xl font-bold">Detalles del hotel</h1>
        </div>
      </div>

      {/* Hotel Image */}
      <div className="h-72 overflow-hidden relative">
        <img
          src={hotel.image}
          alt={`Foto de ${hotel.name}`}
          className="w-full h-full object-cover"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent pointer-events-none" />
      </div>

      {/* Hotel Details */}
      <div className="px-6 py-8 bg-white -mt-6 rounded-t-3xl relative z-0 shadow-lg">
        <div className="flex justify-between items-start mb-4">
          <h2 className="text-3xl font-bold text-[#212121] leading-tight flex-1 mr-4">{hotel.name}</h2>
          <div className="flex items-center gap-1.5 text-[#212121] bg-gray-100 px-3 py-1.5 rounded-xl shadow-sm">
            <Star size={20} className="fill-yellow-500 text-yellow-500" />
            <span className="text-xl font-bold">{hotel.rating}</span>
          </div>
        </div>

        <div className="flex items-center gap-2 text-gray-700 mb-6">
          <MapPin size={20} />
          <span className="text-lg font-medium">{hotel.location}</span>
        </div>

        <div className="mb-8">
          <span className="text-4xl font-bold text-[#1976D2]">{formatPrice(hotel.pricePerNight)}</span>
          <span className="text-lg text-gray-600 ml-2 font-medium">por noche</span>
        </div>

        {/* Description */}
        <div className="mb-8">
          <h3 className="text-2xl font-bold text-[#212121] mb-3">Descripción</h3>
          <p className="text-gray-700 leading-relaxed text-lg">
            {hotel.description}
          </p>
        </div>

        {/* Amenities */}
        <div className="mb-8">
          <h3 className="text-2xl font-bold text-[#212121] mb-4">Servicios</h3>
          <div className="grid grid-cols-3 gap-4">
            {amenities.map((amenity, index) => (
              <div key={index} className="flex flex-col items-center justify-center gap-3 p-4 bg-gray-50 rounded-xl border border-gray-100 shadow-sm">
                <amenity.icon size={32} className="text-[#1976D2]" />
                <span className="text-sm font-medium text-center text-gray-700">{amenity.label}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Reservation Warning */}
      <div className="px-6 py-6">
        <Alert className="bg-amber-50 border-amber-200 rounded-xl p-4 flex items-start gap-3">
          <Clock className="h-6 w-6 text-amber-600 mt-0.5 flex-shrink-0" />
          <AlertDescription className="text-amber-900 text-base font-medium">
            Tu habitación se mantendrá bloqueada por 15 minutos. ¡Reserva pronto!
          </AlertDescription>
        </Alert>
      </div>

      {/* QR Code Section */}
      <div className="px-6 py-6">
        <Card className="p-8 shadow-md rounded-xl border border-gray-200 bg-white">
          <h3 className="text-xl font-bold text-[#212121] mb-6 text-center">
            Código QR para Check-in
          </h3>
          <div className="flex justify-center mb-6">
            <div className="p-4 bg-white rounded-xl border-2 border-gray-200 shadow-sm">
              <QRCodeSVG
                value={qrData}
                size={200}
                level="H"
                includeMargin={false}
              />
            </div>
          </div>
          <p className="text-base text-gray-600 text-center font-medium">
            Presenta este código en la recepción del hotel
          </p>
        </Card>
      </div>

      {/* Booking Summary */}
      {searchParams && (
        <div className="px-6 py-6">
          <Card className="p-6 shadow-md rounded-xl border border-gray-200 bg-white">
            <h3 className="text-xl font-bold text-[#212121] mb-4">Resumen de reserva</h3>
            <div className="space-y-3 text-base">
              <div className="flex justify-between border-b border-gray-100 pb-2">
                <span className="text-gray-600 font-medium">Entrada:</span>
                <span className="text-[#212121] font-bold">{searchParams.checkIn}</span>
              </div>
              <div className="flex justify-between border-b border-gray-100 pb-2">
                <span className="text-gray-600 font-medium">Salida:</span>
                <span className="text-[#212121] font-bold">{searchParams.checkOut}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600 font-medium">Huéspedes:</span>
                <span className="text-[#212121] font-bold">{searchParams.guests} persona(s)</span>
              </div>
            </div>
          </Card>
        </div>
      )}

      {/* Fixed Bottom Button */}
      <div className="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 p-6 shadow-[0_-4px_6px_-1px_rgba(0,0,0,0.1)] z-20">
        <Button
          className="w-full h-16 bg-[#1976D2] hover:bg-[#1565C0] text-white rounded-xl text-xl font-bold shadow-lg transition-transform active:scale-[0.98]"
          onClick={() => {
            alert('¡Reserva confirmada! Recibirás un correo con los detalles.');
          }}
        >
          Confirmar reserva
        </Button>
      </div>
    </div>
  );
}