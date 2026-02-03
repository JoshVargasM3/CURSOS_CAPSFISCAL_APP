import { httpsCallable } from 'firebase/functions';
import { FormEvent, useState } from 'react';
import { collection, getDocs, query, where } from 'firebase/firestore';
import { getFunctions } from 'firebase/functions';

import { db } from '../firebase';

export default function Users() {
  const [email, setEmail] = useState('');
  const [role, setRole] = useState('customer');
  const [message, setMessage] = useState<string | null>(null);

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault();
    setMessage(null);
    const q = query(collection(db, 'users'), where('email', '==', email));
    const snap = await getDocs(q);
    if (snap.empty) {
      setMessage('Usuario no encontrado.');
      return;
    }
    const uid = snap.docs[0].id;
    const functions = getFunctions(undefined, 'us-central1');
    const setRoleCallable = httpsCallable(functions, 'setRole');
    await setRoleCallable({ uid, role });
    setMessage('Rol asignado.');
  };

  return (
    <div style={{ padding: '2rem' }}>
      <h1>Usuarios</h1>
      <form onSubmit={handleSubmit} style={{ display: 'grid', gap: '0.5rem', maxWidth: 360 }}>
        <input value={email} onChange={(e) => setEmail(e.target.value)} placeholder="Email" />
        <select value={role} onChange={(e) => setRole(e.target.value)}>
          <option value="customer">Customer</option>
          <option value="checker">Checker</option>
          <option value="admin">Admin</option>
        </select>
        <button type="submit">Asignar rol</button>
      </form>
      {message && <p>{message}</p>}
    </div>
  );
}
