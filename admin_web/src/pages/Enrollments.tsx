import { collection, onSnapshot, orderBy, query, where } from 'firebase/firestore';
import { useEffect, useState } from 'react';

import { db } from '../firebase';

interface Enrollment {
  id: string;
  uid: string;
  courseId: string;
  status: string;
}

export default function Enrollments() {
  const [enrollments, setEnrollments] = useState<Enrollment[]>([]);
  const [courseId, setCourseId] = useState('');

  useEffect(() => {
    const base = collection(db, 'enrollments');
    const q = courseId
      ? query(base, where('courseId', '==', courseId), orderBy('updatedAt', 'desc'))
      : query(base, orderBy('updatedAt', 'desc'));
    return onSnapshot(q, (snapshot) => {
      setEnrollments(snapshot.docs.map((docSnap) => ({ id: docSnap.id, ...(docSnap.data() as Omit<Enrollment, 'id'>) })));
    });
  }, [courseId]);

  return (
    <div style={{ padding: '2rem' }}>
      <h1>Enrollments</h1>
      <input
        value={courseId}
        onChange={(e) => setCourseId(e.target.value)}
        placeholder="Filtrar por courseId"
      />
      <ul>
        {enrollments.map((enrollment) => (
          <li key={enrollment.id}>
            {enrollment.courseId} - {enrollment.uid} ({enrollment.status})
          </li>
        ))}
      </ul>
    </div>
  );
}
