import { addDoc, collection, onSnapshot, orderBy, query, updateDoc, doc } from 'firebase/firestore';
import { FormEvent, useEffect, useState } from 'react';

import { db } from '../firebase';

interface Course {
  id: string;
  title: string;
  description: string;
  stateId: string;
  sedeId: string;
  startDate: string;
  endDate: string;
  priceFull: number;
  paymentModeAllowed: string;
  isActive: boolean;
}

export default function Courses() {
  const [courses, setCourses] = useState<Course[]>([]);
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [priceFull, setPriceFull] = useState('');
  const [stateId, setStateId] = useState('');
  const [sedeId, setSedeId] = useState('');

  useEffect(() => {
    const q = query(collection(db, 'courses'), orderBy('startDate', 'asc'));
    return onSnapshot(q, (snapshot) => {
      setCourses(snapshot.docs.map((docSnap) => ({ id: docSnap.id, ...(docSnap.data() as Omit<Course, 'id'>) })));
    });
  }, []);

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault();
    await addDoc(collection(db, 'courses'), {
      title,
      description,
      stateId,
      sedeId,
      startDate: new Date().toISOString().slice(0, 10),
      endDate: new Date().toISOString().slice(0, 10),
      priceFull: Number(priceFull || 0),
      paymentModeAllowed: 'both',
      isActive: true,
    });
    setTitle('');
    setDescription('');
    setPriceFull('');
    setStateId('');
    setSedeId('');
  };

  return (
    <div style={{ padding: '2rem' }}>
      <h1>Cursos</h1>
      <form onSubmit={handleSubmit} style={{ display: 'grid', gap: '0.5rem', maxWidth: 500 }}>
        <input value={title} onChange={(e) => setTitle(e.target.value)} placeholder="Título" required />
        <input value={description} onChange={(e) => setDescription(e.target.value)} placeholder="Descripción" required />
        <input value={stateId} onChange={(e) => setStateId(e.target.value)} placeholder="stateId" required />
        <input value={sedeId} onChange={(e) => setSedeId(e.target.value)} placeholder="sedeId" required />
        <input value={priceFull} onChange={(e) => setPriceFull(e.target.value)} placeholder="Precio completo" />
        <button type="submit">Crear</button>
      </form>
      <ul>
        {courses.map((course) => (
          <li key={course.id} style={{ marginTop: '1rem' }}>
            <strong>{course.title}</strong> - {course.description} ({course.isActive ? 'Activo' : 'Inactivo'})
            <button
              style={{ marginLeft: '1rem' }}
              onClick={() => updateDoc(doc(db, 'courses', course.id), { isActive: !course.isActive })}
            >
              Toggle activo
            </button>
          </li>
        ))}
      </ul>
    </div>
  );
}
