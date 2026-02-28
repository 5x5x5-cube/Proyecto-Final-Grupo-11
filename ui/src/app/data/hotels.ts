// Shared hotel data
export const hotels = [
  {
    id: 1,
    name: 'Hotel Mediterráneo',
    image: 'https://images.unsplash.com/photo-1759264244746-140bbbc54e1b?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxtb2Rlcm4lMjBsdXh1cnklMjBob3RlbCUyMHJvb218ZW58MXx8fHwxNzcxODkwMDUxfDA&ixlib=rb-4.1.0&q=80&w=1080',
    pricePerNight: 120,
    rating: 4.8,
    location: 'Centro',
    popular: true,
    description: 'Hotel moderno en el corazón de la ciudad con todas las comodidades.'
  },
  {
    id: 2,
    name: 'Boutique Palace',
    image: 'https://images.unsplash.com/photo-1764391707805-3623b906a8de?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxib3V0aXF1ZSUyMGhvdGVsJTIwZXh0ZXJpb3J8ZW58MXx8fHwxNzcxNzg2MDQ0fDA&ixlib=rb-4.1.0&q=80&w=1080',
    pricePerNight: 95,
    rating: 4.5,
    location: 'Zona histórica',
    popular: true,
    description: 'Encantador hotel boutique con arquitectura clásica y servicio personalizado.'
  },
  {
    id: 3,
    name: 'Beach Resort Vista',
    image: 'https://images.unsplash.com/photo-1729717949780-46e511489c3f?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxyZXNvcnQlMjBob3RlbCUyMGJlYWNofGVufDF8fHx8MTc3MTc3MjQzN3ww&ixlib=rb-4.1.0&q=80&w=1080',
    pricePerNight: 180,
    rating: 4.9,
    location: 'Playa',
    popular: false,
    description: 'Resort exclusivo frente al mar con vistas espectaculares.'
  },
  {
    id: 4,
    name: 'Grand Elegance Hotel',
    image: 'https://images.unsplash.com/photo-1759462692354-404b2c995c99?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxlbGVnYW50JTIwaG90ZWwlMjBsb2JieXxlbnwxfHx8fDE3NzE4Mzk5Mzh8MA&ixlib=rb-4.1.0&q=80&w=1080',
    pricePerNight: 145,
    rating: 4.7,
    location: 'Centro',
    popular: true,
    description: 'Hotel de lujo con lobby elegante y servicios de primera clase.'
  },
  {
    id: 5,
    name: 'Urban Tower Hotel',
    image: 'https://images.unsplash.com/photo-1770017408222-dc83f61d9725?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjaXR5JTIwaG90ZWwlMjBidWlsZGluZ3xlbnwxfHx8fDE3NzE4MjI1MDV8MA&ixlib=rb-4.1.0&q=80&w=1080',
    pricePerNight: 110,
    rating: 4.4,
    location: 'Distrito financiero',
    popular: false,
    description: 'Moderno rascacielos con habitaciones panorámicas y excelente conectividad.'
  },
  {
    id: 6,
    name: 'Cozy Comfort Inn',
    image: 'https://images.unsplash.com/photo-1631048835184-3f0ceda91b75?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxob3RlbCUyMGJlZHJvb20lMjBpbnRlcmlvcnxlbnwxfHx8fDE3NzE4ODMyNDV8MA&ixlib=rb-4.1.0&q=80&w=1080',
    pricePerNight: 75,
    rating: 4.3,
    location: 'Aeropuerto',
    popular: false,
    description: 'Hotel confortable cerca del aeropuerto, ideal para viajes de negocios.'
  }
];

export type Hotel = typeof hotels[0];
