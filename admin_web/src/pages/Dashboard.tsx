import { Link } from 'react-router-dom';

import { useAuth } from '../auth';

export default function Dashboard() {
  const { logout } = useAuth();

  return (
    <div style={{ padding: '2rem' }}>
      <h1>Dashboard Admin</h1>
      <nav style={{ display: 'flex', gap: '1rem', marginBottom: '1rem' }}>
        <Link to="/courses">Cursos</Link>
        <Link to="/enrollments">Enrollments</Link>
        <Link to="/users">Usuarios</Link>
      </nav>
      <button onClick={() => logout()}>Cerrar sesión</button>
    </div>
  );
}
