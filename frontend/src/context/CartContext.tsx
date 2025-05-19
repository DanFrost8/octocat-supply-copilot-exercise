import { createContext, useContext, useState, useEffect, ReactNode } from 'react';

// Define the type for a cart item
export interface CartItem {
  productId: number;
  name: string;
  price: number;
  quantity: number;
  imgName: string;
}

// Define toast notification type
export interface ToastNotification {
  id: string;
  message: string;
  type: 'success' | 'error' | 'info';
}

// Define the cart context type
interface CartContextType {
  cartItems: CartItem[];
  addToCart: (product: any, quantity: number) => void;
  removeFromCart: (productId: number) => void;
  updateQuantity: (productId: number, quantity: number) => void;
  getCartTotal: () => number;
  getCartCount: () => number;
  clearCart: () => void;
  toasts: ToastNotification[];
  removeToast: (id: string) => void;
}

// Local storage key for cart items
const CART_STORAGE_KEY = 'octocat_supply_cart';

// Create the context with default values
const CartContext = createContext<CartContextType>({
  cartItems: [],
  addToCart: () => {},
  removeFromCart: () => {},
  updateQuantity: () => {},
  getCartTotal: () => 0,
  getCartCount: () => 0,
  clearCart: () => {},
  toasts: [],
  removeToast: () => {},
});

// Helper to generate a unique ID
const generateId = () => {
  return Math.random().toString(36).substring(2, 9);
};

// Provider component
export const CartProvider = ({ children }: { children: ReactNode }) => {
  // Initialize state from localStorage or empty array
  const [cartItems, setCartItems] = useState<CartItem[]>(() => {
    try {
      const storedCart = localStorage.getItem(CART_STORAGE_KEY);
      return storedCart ? JSON.parse(storedCart) : [];
    } catch (error) {
      console.error('Error loading cart from localStorage:', error);
      return [];
    }
  });
  
  // State for toast notifications
  const [toasts, setToasts] = useState<ToastNotification[]>([]);
  
  // Save to localStorage whenever cartItems changes
  useEffect(() => {
    try {
      localStorage.setItem(CART_STORAGE_KEY, JSON.stringify(cartItems));
    } catch (error) {
      console.error('Error saving cart to localStorage:', error);
    }
  }, [cartItems]);
  
  const addToast = (message: string, type: 'success' | 'error' | 'info' = 'success') => {
    const newToast = {
      id: generateId(),
      message,
      type
    };
    setToasts(prev => [...prev, newToast]);
  };
  
  const removeToast = (id: string) => {
    setToasts(prev => prev.filter(toast => toast.id !== id));
  };
  
  const addToCart = (product: any, quantity: number) => {
    if (quantity <= 0) return;
    
    setCartItems(prevItems => {
      const existingItem = prevItems.find(item => item.productId === product.productId);
      
      if (existingItem) {
        addToast(`Updated ${product.name} quantity in your cart`);
        return prevItems.map(item => 
          item.productId === product.productId 
            ? { ...item, quantity: item.quantity + quantity } 
            : item
        );
      }
      
      addToast(`Added ${product.name} to your cart`);
      return [...prevItems, { 
        productId: product.productId,
        name: product.name,
        price: product.price,
        quantity,
        imgName: product.imgName
      }];
    });
  };
  
  const removeFromCart = (productId: number) => {
    const productToRemove = cartItems.find(item => item.productId === productId);
    if (productToRemove) {
      addToast(`Removed ${productToRemove.name} from your cart`, 'info');
    }
    
    setCartItems(prevItems => prevItems.filter(item => item.productId !== productId));
  };
  
  const updateQuantity = (productId: number, quantity: number) => {
    if (quantity < 1) return;
    
    setCartItems(prevItems => 
      prevItems.map(item => 
        item.productId === productId ? { ...item, quantity } : item
      )
    );
  };
  
  const getCartTotal = () => {
    return cartItems.reduce((total, item) => total + (item.price * item.quantity), 0);
  };
  
  const getCartCount = () => {
    return cartItems.reduce((count, item) => count + item.quantity, 0);
  };
  
  const clearCart = () => {
    setCartItems([]);
    addToast('Your cart has been cleared', 'info');
  };
  
  return (
    <CartContext.Provider value={{ 
      cartItems, 
      addToCart, 
      removeFromCart, 
      updateQuantity, 
      getCartTotal,
      getCartCount,
      clearCart,
      toasts,
      removeToast
    }}>
      {children}
    </CartContext.Provider>
  );
};

// Custom hook for using the cart context
export const useCart = () => useContext(CartContext);
