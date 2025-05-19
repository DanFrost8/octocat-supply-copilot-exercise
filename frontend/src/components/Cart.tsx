import { useState } from 'react';
import { Link } from 'react-router-dom';
import { useCart } from '../context/CartContext';
import '../styles/Cart.css';

export default function Cart() {
  const { cartItems, removeFromCart, updateQuantity, getCartTotal } = useCart();
  const [couponCode, setCouponCode] = useState('');
  const [discount, setDiscount] = useState(0);
  
  const shippingCost = cartItems.length > 0 ? 10 : 0;
  const subtotal = getCartTotal();
  const discountAmount = (subtotal * discount) / 100;
  const grandTotal = subtotal - discountAmount + shippingCost;
  
  const applyCoupon = () => {
    // Simple coupon logic - in a real app, this would validate against a backend
    if (couponCode.toLowerCase() === 'save5') {
      setDiscount(5);
    } else {
      alert('Invalid coupon code');
    }
  };
  
  const handleQuantityChange = (productId: number, newQuantity: number) => {
    if (newQuantity >= 1) {
      updateQuantity(productId, parseInt(newQuantity.toString()));
    }
  };
  
  if (cartItems.length === 0) {
    return (
      <div className="min-h-screen bg-dark pt-20 px-4">
        <div className="max-w-7xl mx-auto py-12">
          <div className="text-center">
            <h2 className="text-3xl font-bold text-light mb-4">Your cart is empty</h2>
            <p className="text-gray-400 mb-8">Looks like you haven't added any products to your cart yet.</p>
            <Link 
              to="/products" 
              className="bg-primary hover:bg-accent text-white px-6 py-3 rounded-md font-medium transition-colors"
            >
              Continue Shopping
            </Link>
          </div>
        </div>
      </div>
    );
  }
  
  return (
    <div className="min-h-screen bg-dark pt-20 px-4">
      <div className="max-w-7xl mx-auto py-12">
        <h1 className="text-3xl font-bold text-light mb-8">Your Cart</h1>
        
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div className="lg:col-span-2 overflow-x-auto">
            <table className="min-w-full bg-dark-light rounded-lg overflow-hidden">
              <thead className="bg-dark-light border-b border-gray-700">
                <tr>
                  <th className="py-3 px-4 text-left text-light">S. No.</th>
                  <th className="py-3 px-4 text-left text-light">Product Image</th>
                  <th className="py-3 px-4 text-left text-light">Product Name</th>
                  <th className="py-3 px-4 text-left text-light">Unit Price</th>
                  <th className="py-3 px-4 text-left text-light">Quantity</th>
                  <th className="py-3 px-4 text-left text-light">Total</th>
                  <th className="py-3 px-4 text-left text-light">Remove</th>
                </tr>
              </thead>
              <tbody>
                {cartItems.map((item, index) => (
                  <tr key={item.productId} className="border-b border-gray-700">
                    <td className="py-4 px-4 text-light">{index + 1}</td>
                    <td className="py-4 px-4">
                      <img 
                        src={`/${item.imgName}`} 
                        alt={item.name} 
                        className="w-20 h-20 object-contain"
                      />
                    </td>
                    <td className="py-4 px-4 text-light">{item.name}</td>
                    <td className="py-4 px-4 text-light">${item.price}</td>
                    <td className="py-4 px-4">
                      <div className="flex items-center">
                        <button 
                          onClick={() => handleQuantityChange(item.productId, item.quantity - 1)}
                          className="bg-dark-light text-light px-2 py-1 rounded"
                        >
                          -
                        </button>
                        <input 
                          type="number" 
                          min="1" 
                          value={item.quantity}
                          onChange={(e) => handleQuantityChange(item.productId, parseInt(e.target.value))}
                          className="w-12 mx-2 cart-input text-center"
                        />
                        <button 
                          onClick={() => handleQuantityChange(item.productId, item.quantity + 1)}
                          className="bg-dark-light text-light px-2 py-1 rounded"
                        >
                          +
                        </button>
                      </div>
                    </td>
                    <td className="py-4 px-4 text-light">${(item.price * item.quantity).toFixed(2)}</td>
                    <td className="py-4 px-4">
                      <button 
                        onClick={() => removeFromCart(item.productId)}
                        className="text-red-500 hover:text-red-400"
                      >
                        <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                        </svg>
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          
          <div className="bg-dark-light p-6 rounded-lg h-fit">
            <h2 className="text-xl font-bold text-light mb-4">Order Summary</h2>
            
            <div className="space-y-3 mb-6">
              <div className="flex justify-between text-light">
                <span>Subtotal</span>
                <span>${subtotal.toFixed(2)}</span>
              </div>
              
              {discount > 0 && (
                <div className="flex justify-between text-green-400">
                  <span>Discount ({discount}%)</span>
                  <span>-${discountAmount.toFixed(2)}</span>
                </div>
              )}
              
              <div className="flex justify-between text-light">
                <span>Shipping</span>
                <span>${shippingCost.toFixed(2)}</span>
              </div>
              
              <div className="border-t border-gray-700 pt-3 flex justify-between text-light font-bold">
                <span>Grand Total</span>
                <span>${grandTotal.toFixed(2)}</span>
              </div>
            </div>
            
            <div className="flex mb-6">
              <input
                type="text"
                placeholder="Coupon Code"
                className="flex-grow coupon-input"
                value={couponCode}
                onChange={(e) => setCouponCode(e.target.value)}
              />
              <button 
                onClick={applyCoupon}
                className="bg-primary hover:bg-accent text-white px-4 py-2 rounded-r transition-colors"
              >
                Apply Coupon
              </button>
            </div>
            
            <button className="w-full bg-primary hover:bg-accent text-white py-3 rounded-md font-medium transition-colors mb-4">
              Proceed To Checkout
            </button>
            
            <Link to="/products" className="block text-center text-primary hover:text-accent">
              Continue Shopping
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}
