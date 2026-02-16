import React from 'react';
import { Home, Map, CircleDot, User, Sparkles, HeartHandshake, Key } from 'lucide-react';
import { useTranslation } from '../lib/i18n_context';
import { SalesBot } from './components/SalesBot';

interface LayoutProps {
  children: React.ReactNode;
  currentView: string;
  onNavigate: (view: string) => void;
}

export const Layout: React.FC<LayoutProps> = ({ children, currentView, onNavigate }) => {
  const { t } = useTranslation();
  
  // Navigation Items
  const navItems = [
    { id: 'dashboard', icon: Home, label: 'Altar' },
    { id: 'journey', icon: Map, label: 'Journey' },
    { id: 'community', icon: HeartHandshake, label: 'Community' },
    { id: 'confessional', icon: Key, label: 'Confess' }, // New Item
    { id: 'profile', icon: User, label: 'Profile' },
  ];

  return (
    <div className="min-h-screen bg-[#F9F7F2] flex">
      
      {/* DESKTOP SIDEBAR */}
      <aside className="hidden md:flex flex-col w-64 fixed h-full bg-white/80 backdrop-blur-md border-r border-gray-100 z-40">
        <div className="p-8 flex items-center gap-3">
           <div className="h-10 w-10 rounded-full bg-gradient-to-tr from-angel-gold to-yellow-300 flex items-center justify-center shadow-lg">
             <span className="text-white font-serif font-bold text-xl">A</span>
           </div>
           <span className="font-serif font-bold text-gray-800 tracking-wide text-lg">The Calling</span>
        </div>
        
        <nav className="flex-1 px-4 space-y-2 mt-4">
          {navItems.map((item) => (
            <button 
              key={item.id}
              onClick={() => onNavigate(item.id)}
              className={`w-full flex items-center gap-4 px-4 py-3 rounded-xl transition-all duration-300 group
                ${currentView === item.id
                  ? 'bg-angel-gold/10 text-angel-gold font-semibold' 
                  : 'text-gray-500 hover:bg-gray-50 hover:text-gray-800'
                }`}
            >
              <item.icon className={`w-5 h-5 ${currentView === item.id ? 'stroke-[2.5px]' : 'stroke-2'}`} />
              <span className="font-sans">{item.label}</span>
              {currentView === item.id && <div className="ml-auto w-1.5 h-1.5 rounded-full bg-angel-gold shadow-[0_0_8px_rgba(212,175,55,0.6)]"></div>}
            </button>
          ))}
        </nav>

        <div className="p-6 border-t border-gray-100">
           <div className="bg-gradient-to-br from-gray-900 to-gray-800 rounded-xl p-4 text-white relative overflow-hidden">
             <div className="absolute top-0 right-0 w-20 h-20 bg-white/10 rounded-full blur-2xl -mr-10 -mt-10"></div>
             <p className="text-xs text-gray-400 uppercase tracking-widest font-bold mb-1">Status</p>
             <p className="font-serif text-lg">Seraphim</p>
           </div>
        </div>
      </aside>

      {/* MAIN CONTENT WRAPPER */}
      <main className="flex-1 md:ml-64 relative min-h-screen">
        {children}
      </main>

      {/* MOBILE BOTTOM NAVIGATION */}
      <nav className="md:hidden fixed bottom-0 w-full glass-nav z-50 pb-safe">
        <div className="flex justify-around items-center h-16 px-2">
          {navItems.map((item) => (
            <button 
              key={item.id}
              onClick={() => onNavigate(item.id)}
              className={`flex flex-col items-center justify-center w-16 h-full transition-colors relative
                ${currentView === item.id ? 'text-angel-gold' : 'text-gray-400 hover:text-gray-600'}`}
            >
              <item.icon className={`w-6 h-6 ${currentView === item.id ? 'stroke-[2.5px]' : 'stroke-2'}`} />
              <span className="text-[10px] font-sans mt-1 font-medium">{item.label}</span>
              {currentView === item.id && (
                <span className="absolute -bottom-0.5 w-1 h-1 bg-angel-gold rounded-full shadow-[0_0_8px_rgba(212,175,55,1)]"></span>
              )}
            </button>
          ))}
        </div>
      </nav>

      {/* ANGELIC SALES BOT (GLOBAL) */}
      <SalesBot />
    </div>
  );
};