import { useState, useEffect } from 'react';
import './App.css';

const API = '/api/todos';

export default function App() {
  const [todos, setTodos] = useState([]);
  const [input, setInput] = useState('');
  const [error, setError] = useState('');

  const fetchTodos = async () => {
    try {
      const res = await fetch(API);
      const data = await res.json();
      setTodos(data);
    } catch {
      setError('Could not load todos.');
    }
  };

  useEffect(() => {
    fetchTodos();
  }, []);

  const addTodo = async (e) => {
    e.preventDefault();
    if (!input.trim()) return;
    try {
      const res = await fetch(API, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ title: input.trim() }),
      });
      if (!res.ok) throw new Error();
      const todo = await res.json();
      setTodos([todo, ...todos]);
      setInput('');
    } catch {
      setError('Failed to add todo.');
    }
  };

  const toggleTodo = async (id) => {
    try {
      const res = await fetch(`${API}/${id}`, { method: 'PATCH' });
      if (!res.ok) throw new Error();
      const updated = await res.json();
      setTodos(todos.map((t) => (t.id === updated.id ? updated : t)));
    } catch {
      setError('Failed to update todo.');
    }
  };

  const deleteTodo = async (id) => {
    try {
      const res = await fetch(`${API}/${id}`, { method: 'DELETE' });
      if (!res.ok) throw new Error();
      setTodos(todos.filter((t) => t.id !== id));
    } catch {
      setError('Failed to delete todo.');
    }
  };

  return (
    <div className="app">
      <h1>Todo App</h1>

      {error && <p className="error">{error}</p>}

      <form onSubmit={addTodo} className="add-form">
        <input
          type="text"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder="What needs to be done?"
          maxLength={200}
        />
        <button type="submit">Add</button>
      </form>

      <ul className="todo-list">
        {todos.length === 0 && <li className="empty">No todos yet.</li>}
        {todos.map((todo) => (
          <li key={todo.id} className={todo.completed ? 'completed' : ''}>
            <span onClick={() => toggleTodo(todo.id)}>{todo.title}</span>
            <button
              className="delete-btn"
              onClick={() => deleteTodo(todo.id)}
              aria-label="Delete"
            >
              ✕
            </button>
          </li>
        ))}
      </ul>
    </div>
  );
}
