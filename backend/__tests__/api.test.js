const request = require('supertest');
const app = require('../index');

// Mock the db module so tests never touch a real database
jest.mock('../db', () => ({
  initDb: jest.fn().mockResolvedValue(undefined),
  pool: { query: jest.fn() },
}));

const { pool } = require('../db');

beforeEach(() => {
  jest.spyOn(console, 'error').mockImplementation(() => {});
});

afterEach(() => {
  jest.restoreAllMocks();
  jest.clearAllMocks();
});

// ---------------------------------------------------------------------------
// GET /api/health
// ---------------------------------------------------------------------------
describe('GET /api/health', () => {
  it('returns status ok', async () => {
    const res = await request(app).get('/api/health');
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ status: 'ok' });
  });
});

// ---------------------------------------------------------------------------
// GET /api/todos
// ---------------------------------------------------------------------------
describe('GET /api/todos', () => {
  it('returns all todos from the database', async () => {
    const rows = [
      { id: 1, title: 'Buy milk', completed: false },
      { id: 2, title: 'Walk dog', completed: true },
    ];
    pool.query.mockResolvedValueOnce({ rows });

    const res = await request(app).get('/api/todos');
    expect(res.status).toBe(200);
    expect(res.body).toEqual(rows);
    expect(pool.query).toHaveBeenCalledWith(
      'SELECT * FROM todos ORDER BY created_at DESC'
    );
  });

  it('returns 500 when the database query fails', async () => {
    pool.query.mockRejectedValueOnce(new Error('DB error'));

    const res = await request(app).get('/api/todos');
    expect(res.status).toBe(500);
    expect(res.body).toEqual({ error: 'Failed to fetch todos' });
  });
});

// ---------------------------------------------------------------------------
// POST /api/todos
// ---------------------------------------------------------------------------
describe('POST /api/todos', () => {
  it('creates and returns a new todo', async () => {
    const newTodo = { id: 3, title: 'Read book', completed: false };
    pool.query.mockResolvedValueOnce({ rows: [newTodo] });

    const res = await request(app)
      .post('/api/todos')
      .send({ title: 'Read book' });

    expect(res.status).toBe(201);
    expect(res.body).toEqual(newTodo);
    expect(pool.query).toHaveBeenCalledWith(
      'INSERT INTO todos (title) VALUES ($1) RETURNING *',
      ['Read book']
    );
  });

  it('trims whitespace from the title', async () => {
    const newTodo = { id: 4, title: 'Clean house', completed: false };
    pool.query.mockResolvedValueOnce({ rows: [newTodo] });

    const res = await request(app)
      .post('/api/todos')
      .send({ title: '  Clean house  ' });

    expect(res.status).toBe(201);
    expect(pool.query).toHaveBeenCalledWith(
      expect.any(String),
      ['Clean house']
    );
  });

  it('returns 400 when title is missing', async () => {
    const res = await request(app).post('/api/todos').send({});
    expect(res.status).toBe(400);
    expect(res.body).toEqual({ error: 'Title is required' });
    expect(pool.query).not.toHaveBeenCalled();
  });

  it('returns 400 when title is only whitespace', async () => {
    const res = await request(app).post('/api/todos').send({ title: '   ' });
    expect(res.status).toBe(400);
    expect(res.body).toEqual({ error: 'Title is required' });
  });

  it('returns 400 when title is not a string', async () => {
    const res = await request(app).post('/api/todos').send({ title: 123 });
    expect(res.status).toBe(400);
    expect(res.body).toEqual({ error: 'Title is required' });
  });

  it('returns 500 when the database query fails', async () => {
    pool.query.mockRejectedValueOnce(new Error('DB error'));

    const res = await request(app)
      .post('/api/todos')
      .send({ title: 'Will fail' });
    expect(res.status).toBe(500);
    expect(res.body).toEqual({ error: 'Failed to create todo' });
  });
});

// ---------------------------------------------------------------------------
// PATCH /api/todos/:id
// ---------------------------------------------------------------------------
describe('PATCH /api/todos/:id', () => {
  it('toggles completed and returns the updated todo', async () => {
    const updated = { id: 1, title: 'Buy milk', completed: true };
    pool.query.mockResolvedValueOnce({ rows: [updated] });

    const res = await request(app).patch('/api/todos/1');
    expect(res.status).toBe(200);
    expect(res.body).toEqual(updated);
    expect(pool.query).toHaveBeenCalledWith(
      'UPDATE todos SET completed = NOT completed WHERE id = $1 RETURNING *',
      ['1']
    );
  });

  it('returns 404 when the todo does not exist', async () => {
    pool.query.mockResolvedValueOnce({ rows: [] });

    const res = await request(app).patch('/api/todos/999');
    expect(res.status).toBe(404);
    expect(res.body).toEqual({ error: 'Todo not found' });
  });

  it('returns 500 when the database query fails', async () => {
    pool.query.mockRejectedValueOnce(new Error('DB error'));

    const res = await request(app).patch('/api/todos/1');
    expect(res.status).toBe(500);
    expect(res.body).toEqual({ error: 'Failed to update todo' });
  });
});

// ---------------------------------------------------------------------------
// DELETE /api/todos/:id
// ---------------------------------------------------------------------------
describe('DELETE /api/todos/:id', () => {
  it('deletes the todo and returns 204', async () => {
    pool.query.mockResolvedValueOnce({ rows: [{ id: 1 }] });

    const res = await request(app).delete('/api/todos/1');
    expect(res.status).toBe(204);
    expect(pool.query).toHaveBeenCalledWith(
      'DELETE FROM todos WHERE id = $1 RETURNING *',
      ['1']
    );
  });

  it('returns 404 when the todo does not exist', async () => {
    pool.query.mockResolvedValueOnce({ rows: [] });

    const res = await request(app).delete('/api/todos/999');
    expect(res.status).toBe(404);
    expect(res.body).toEqual({ error: 'Todo not found' });
  });

  it('returns 500 when the database query fails', async () => {
    pool.query.mockRejectedValueOnce(new Error('DB error'));

    const res = await request(app).delete('/api/todos/1');
    expect(res.status).toBe(500);
    expect(res.body).toEqual({ error: 'Failed to delete todo' });
  });
});
