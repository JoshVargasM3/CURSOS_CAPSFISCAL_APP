import { useEffect, useState } from 'react';
import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { getIdTokenResult } from 'firebase/auth';

import { AuthProvider, useAuth } from './auth';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Courses from './pages/Courses';
import Enrollments from './pages/Enrollments';
import Users from './pages/Users';

function RequireAdmin({ children }: { children: JSX.Element }) {
  const { user, loading } = useAuth();
  const [isAdmin, setIsAdmin] = useState<boolean | null>(null);

  useEffect(() => {
    async function checkRole() {
      if (!user) {
        setIsAdmin(false);
        return;
      }
      const token = await getIdTokenResult(user, true);
      setIsAdmin(token.claims.role === 'admin');
    }
    checkRole();
  }, [user]);

  if (loading || isAdmin === null) {
    return <div>Verificando acceso...</div>;
  }

  if (!user || !isAdmin) {
    return <Navigate to="/login" replace />;
  }

  return children;
}

function AppRoutes() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route
        path="/"
        element={
          <RequireAdmin>
            <Dashboard />
          </RequireAdmin>
        }
      />
      <Route
        path="/courses"
        element={
          <RequireAdmin>
            <Courses />
          </RequireAdmin>
        }
      />
      <Route
        path="/enrollments"
        element={
          <RequireAdmin>
            <Enrollments />
          </RequireAdmin>
        }
      />
      <Route
        path="/users"
        element={
          <RequireAdmin>
            <Users />
          </RequireAdmin>
        }
      />
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <AppRoutes />
      </BrowserRouter>
    </AuthProvider>
  );
}
