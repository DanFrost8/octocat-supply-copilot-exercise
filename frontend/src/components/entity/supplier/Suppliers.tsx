import { useState } from 'react';
import axios from 'axios';
import { useQuery } from 'react-query';
import { api } from '../../../api/config';

interface Supplier {
  // Unique identifier for the supplier
  supplierId: number;

  // Name of the supplier
  name: string;

  // Description of the supplier's business or services
  description: string;

  // Contact person at the supplier
  contactPerson?: string;

  // Email address of the supplier
  email: string;
  
  // Phone number of the supplier
  phone: string;
}

const fetchSuppliers = async (): Promise<Supplier[]> => {
  const { data } = await axios.get(`${api.baseURL}${api.endpoints.suppliers}`);
  return data;
};

export default function Suppliers() {
  const { data: suppliers, isLoading, error } = useQuery('suppliers', fetchSuppliers);

  if (isLoading) {
    return (
      <div className="min-h-screen bg-dark pt-20 px-4">
        <div className="max-w-7xl mx-auto">
          <div className="flex justify-center items-center h-64">
            <div className="animate-spin rounded-full h-32 w-32 sm:h-16 sm:w-16 border-t-2 border-b-2 border-primary"></div>
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-dark pt-20 px-4">
        <div className="max-w-7xl mx-auto">
          <div className="text-red-500 text-center">
            Failed to fetch suppliers. Please check your internet connection or try again later.
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-dark pt-20 px-4">
      <div className="max-w-7xl mx-auto">
        <h1 className="text-3xl font-bold text-light mb-6">Our Suppliers</h1>
        
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {suppliers?.map((supplier, index) => (
            <div key={`${supplier.supplierId}-${index}`} className="bg-gray-800 rounded-lg overflow-hidden shadow-lg p-6 hover:shadow-[0_0_25px_rgba(118,184,82,0.3)] transition-all duration-300">
              <h2 className="text-xl font-semibold text-primary mb-2">{supplier.name}</h2>
              
              {supplier.description && (
                <p className="text-gray-300 mb-4">{supplier.description}</p>
              )}
              
              <div className="border-t border-gray-700 pt-4 mt-4">
                <h3 className="text-light font-medium mb-2">Contact Information</h3>
                
                <div className="space-y-2">
                  {supplier.contactPerson && (
                    <div className="flex items-start">
                      <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5 text-primary mr-2 mt-0.5" viewBox="0 0 20 20" fill="currentColor">
                        <path fillRule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clipRule="evenodd" />
                      </svg>
                      <span className="text-gray-300">{supplier.contactPerson}</span>
                    </div>
                  )}
                  
                  {supplier.email && (
                    <div className="flex items-start">
                      <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5 text-primary mr-2 mt-0.5" viewBox="0 0 20 20" fill="currentColor">
                        <path d="M2.003 5.884L10 9.882l7.997-3.998A2 2 0 0016 4H4a2 2 0 00-1.997 1.884z" />
                        <path d="M18 8.118l-8 4-8-4V14a2 2 0 002 2h12a2 2 0 002-2V8.118z" />
                      </svg>
                      <a href={`mailto:${supplier.email}`} className="text-gray-300 hover:text-primary transition-colors">{supplier.email}</a>
                    </div>
                  )}
                  
                  {supplier.phone && (
                    <div className="flex items-start">
                      <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5 text-primary mr-2 mt-0.5" viewBox="0 0 20 20" fill="currentColor">
                        <path d="M2 3a1 1 0 011-1h2.153a1 1 0 01.986.836l.74 4.435a1 1 0 01-.54 1.06l-1.548.773a11.037 11.037 0 006.105 6.105l.774-1.548a1 1 0 011.059-.54l4.435.74a1 1 0 01.836.986V17a1 1 0 01-1 1h-2C7.82 18 2 12.18 2 5V3z" />
                      </svg>
                      <a href={`tel:${supplier.phone}`} className="text-gray-300 hover:text-primary transition-colors">{supplier.phone}</a>
                    </div>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
