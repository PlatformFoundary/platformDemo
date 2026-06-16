import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { vi } from 'vitest';
import App from '../App';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
const mockTodos = [
  { id: 1, title: 'Buy milk', completed: false, created_at: '2026-01-01T00:00:00Z' },
  { id: 2, title: 'Walk dog', completed: true, created_at: '2026-01-02T00:00:00Z' },
];

const mockFetch = (responses) => {
  let callIndex = 0;
  global.fetch = vi.fn(() => {
    const response = Array.isArray(responses)
      ? responses[callIndex++] ?? responses[responses.length - 1]
      : responses;
    return Promise.resolve(response);
  });
};

const jsonResponse = (data, status = 200) => ({
  ok: status >= 200 && status < 300,
  status,
  json: () => Promise.resolve(data),
});

afterEach(() => {
  vi.restoreAllMocks();
});

// ---------------------------------------------------------------------------
// Initial render
// ---------------------------------------------------------------------------
describe('App — initial render', () => {
  it('renders the heading', async () => {
    mockFetch(jsonResponse([]));
    render(<App />);
    expect(screen.getByText('Todo App')).toBeInTheDocument();
  });

  it('renders the add-form input and button', async () => {
    mockFetch(jsonResponse([]));
    render(<App />);
    expect(screen.getByPlaceholderText('What needs to be done?')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /add/i })).toBeInTheDocument();
  });

  it('fetches and displays todos on mount', async () => {
    mockFetch(jsonResponse(mockTodos));
    render(<App />);

    await waitFor(() => {
      expect(screen.getByText('Buy milk')).toBeInTheDocument();
      expect(screen.getByText('Walk dog')).toBeInTheDocument();
    });
  });

  it('shows "No todos yet." when list is empty', async () => {
    mockFetch(jsonResponse([]));
    render(<App />);

    await waitFor(() => {
      expect(screen.getByText('No todos yet.')).toBeInTheDocument();
    });
  });

  it('shows completed todos with line-through styling', async () => {
    mockFetch(jsonResponse(mockTodos));
    render(<App />);

    await waitFor(() => {
      const completed = screen.getByText('Walk dog').closest('li');
      expect(completed).toHaveClass('completed');
    });
  });

  it('shows an error message when initial fetch fails', async () => {
    global.fetch = vi.fn(() => Promise.reject(new Error('Network error')));
    render(<App />);

    await waitFor(() => {
      expect(screen.getByText('Could not load todos.')).toBeInTheDocument();
    });
  });
});

// ---------------------------------------------------------------------------
// Adding a todo
// ---------------------------------------------------------------------------
describe('App — adding a todo', () => {
  it('adds a new todo and clears the input', async () => {
    const newTodo = { id: 3, title: 'Read book', completed: false };
    mockFetch([jsonResponse([]), jsonResponse(newTodo, 201)]);
    render(<App />);

    const input = screen.getByPlaceholderText('What needs to be done?');
    await userEvent.type(input, 'Read book');
    await userEvent.click(screen.getByRole('button', { name: /add/i }));

    await waitFor(() => {
      expect(screen.getByText('Read book')).toBeInTheDocument();
    });
    expect(input).toHaveValue('');
  });

  it('does not submit when input is empty', async () => {
    mockFetch(jsonResponse([]));
    render(<App />);

    await userEvent.click(screen.getByRole('button', { name: /add/i }));

    // fetch is called once (initial load) but not again for the empty submit
    expect(global.fetch).toHaveBeenCalledTimes(1);
  });

  it('shows an error when the POST request fails', async () => {
    mockFetch([jsonResponse([]), jsonResponse({}, 500)]);
    render(<App />);

    const input = screen.getByPlaceholderText('What needs to be done?');
    await userEvent.type(input, 'Will fail');
    await userEvent.click(screen.getByRole('button', { name: /add/i }));

    await waitFor(() => {
      expect(screen.getByText('Failed to add todo.')).toBeInTheDocument();
    });
  });
});

// ---------------------------------------------------------------------------
// Toggling a todo
// ---------------------------------------------------------------------------
describe('App — toggling a todo', () => {
  it('toggles a todo when its title is clicked', async () => {
    const toggled = { ...mockTodos[0], completed: true };
    mockFetch([jsonResponse(mockTodos), jsonResponse(toggled)]);
    render(<App />);

    await waitFor(() => screen.getByText('Buy milk'));
    fireEvent.click(screen.getByText('Buy milk'));

    await waitFor(() => {
      const li = screen.getByText('Buy milk').closest('li');
      expect(li).toHaveClass('completed');
    });
  });

  it('shows an error when the PATCH request fails', async () => {
    mockFetch([jsonResponse(mockTodos), jsonResponse({}, 500)]);
    render(<App />);

    await waitFor(() => screen.getByText('Buy milk'));
    fireEvent.click(screen.getByText('Buy milk'));

    await waitFor(() => {
      expect(screen.getByText('Failed to update todo.')).toBeInTheDocument();
    });
  });
});

// ---------------------------------------------------------------------------
// Deleting a todo
// ---------------------------------------------------------------------------
describe('App — deleting a todo', () => {
  it('removes the todo from the list on delete', async () => {
    mockFetch([
      jsonResponse(mockTodos),
      { ok: true, status: 204, json: () => Promise.resolve({}) },
    ]);
    render(<App />);

    await waitFor(() => screen.getByText('Buy milk'));

    const deleteButtons = screen.getAllByRole('button', { name: /delete/i });
    fireEvent.click(deleteButtons[0]);

    await waitFor(() => {
      expect(screen.queryByText('Buy milk')).not.toBeInTheDocument();
    });
  });

  it('shows an error when the DELETE request fails', async () => {
    mockFetch([jsonResponse(mockTodos), jsonResponse({}, 500)]);
    render(<App />);

    await waitFor(() => screen.getByText('Buy milk'));
    const deleteButtons = screen.getAllByRole('button', { name: /delete/i });
    fireEvent.click(deleteButtons[0]);

    await waitFor(() => {
      expect(screen.getByText('Failed to delete todo.')).toBeInTheDocument();
    });
  });
});
