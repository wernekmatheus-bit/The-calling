
import React, { useEffect, useState } from 'react';
import { I18nProvider, useTranslation } from './lib/i18n_context';
import { Layout } from './components/Layout';
import { AuthPage } from './pages/Auth';
import { Dashboard } from './pages/Dashboard';
import { CourseViewer } from './pages/CourseViewer';
import { Courses } from './pages/Courses';
import { Journey } from './pages/Journey';
import { Community } from './pages/Community';
import { Confessional } from './pages/Confessional';
import { BibleReader } from './pages/BibleReader';
import { Profile } from './pages/Profile';
import { Empatia } from './pages/Empatia';
import { supabase } from './lib/supabase';
import { Session } from '@supabase/supabase-js';
import { Toaster } from 'sonner';

// Helper component to use the hook inside the provider
const AppInner: React.FC = () => {
  const { t } = useTranslation();
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);
  const [currentView, setCurrentView] = useState<string>('dashboard');

  useEffect(() => {
    // 1. Check active session on load
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
      setLoading(false);
    });

    // 2. Listen for auth changes (Login, Logout, Token Refresh)
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session);
      setLoading(false);
    });

    return () => subscription.unsubscribe();
  }, []);

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[#F9F7F2]">
        <div className="animate-pulse flex flex-col items-center">
          <div className="h-12 w-12 bg-angel-gold rounded-full opacity-50 mb-4 shadow-[0_0_20px_#D4AF37]"></div>
          <div className="h-4 w-32 bg-gray-200 rounded"></div>
        </div>
      </div>
    );
  }

  // CRITICAL: Ensure we only render main app if session exists
  const isAuthenticated = !!session;

  if (!isAuthenticated) {
    return (
      <AuthPage 
        onLoginSuccess={() => {}} // Handled automatically by onAuthStateChange
      />
    );
  }

  const renderView = () => {
    switch(currentView) {
      case 'courses': return <Courses onNavigate={setCurrentView} />;
      case 'dashboard': return <Dashboard onNavigate={setCurrentView} />;
      case 'confessional': return <Confessional onBack={() => setCurrentView('dashboard')} />;
      case 'bible': return <BibleReader />; 
      case 'journey': return <Journey />;
      case 'community': return <Community />;
      case 'course': return <CourseViewer />; 
      case 'profile': return <Profile onNavigate={setCurrentView} />;
      case 'empatia': return <Empatia onNavigate={setCurrentView} />;
      default: return <Dashboard onNavigate={setCurrentView} />;
    }
  };

  return (
    <Layout currentView={currentView} onNavigate={setCurrentView}>
      <Toaster position="top-center" />
      {renderView()}
    </Layout>
  );
};

const App: React.FC = () => {
  return (
    <I18nProvider>
      <AppInner />
    </I18nProvider>
  );
};

export default App;
