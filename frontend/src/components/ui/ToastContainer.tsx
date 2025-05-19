import { useCart, ToastNotification } from '../../context/CartContext';
import Toast from './Toast';

export default function ToastContainer() {
  const { toasts, removeToast } = useCart();
  
  if (toasts.length === 0) return null;
  
  return (
    <div className="toast-container">
      {toasts.map((toast: ToastNotification) => (
        <Toast
          key={toast.id}
          message={toast.message}
          type={toast.type}
          onClose={() => removeToast(toast.id)}
        />
      ))}
    </div>
  );
}
