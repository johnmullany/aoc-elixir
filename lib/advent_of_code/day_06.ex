defmodule AdventOfCode.Day06 do
  def part1(input) do
    grid = parse_grid(input)
    start_pos = find_start_position(grid)
    
    # Track path starting from start position facing up
    {path, _} = walk_path(grid, start_pos, :up)
    
    # Visualize the path
    visualize_path(grid, path)
    
    # Count unique positions in path
    MapSet.size(path)
  end

  def part2(input) do
    grid = parse_grid(input)
    start_pos = find_start_position(grid)
    
    # Get all possible positions (excluding start and existing obstacles)
    all_positions = for y <- 0..(length(grid) - 1),
                       x <- 0..(length(Enum.at(grid, 0)) - 1),
                       {x, y} != start_pos,
                       Enum.at(grid, y) |> Enum.at(x) != "#",
                       do: {x, y}
    
    # Try each position and count those that create loops
    all_positions
    |> Enum.count(fn pos -> creates_loop?(grid, start_pos, pos) end)
  end

  defp parse_grid(input) do
    input
    |> String.split("\n", trim: true)
    |> Enum.map(&String.graphemes/1)
  end

  defp find_start_position(grid) do
    grid
    |> Enum.with_index()
    |> Enum.find_value(fn {row, y} ->
      case Enum.find_index(row, &(&1 == "^")) do
        nil -> nil
        x -> {x, y}
      end
    end)
  end

  defp walk_path(grid, pos, dir) do
    walk_path_rec(grid, pos, dir, MapSet.new([pos]), MapSet.new())
  end

  defp walk_path_rec(grid, pos, dir, path, visited_states) do
    walk_path_step(grid, pos, dir, path, visited_states, {MapSet.member?(visited_states, {pos, dir}), at_edge?(grid, pos)})
  end

  defp walk_path_step(_grid, _pos, _dir, path, visited_states, {true, _}), do: {path, visited_states}
  defp walk_path_step(_grid, _pos, _dir, path, visited_states, {_, true}), do: {path, visited_states}
  defp walk_path_step(grid, pos, dir, path, visited_states, {false, false}) do
    {next_pos, next_dir} = get_next_move(grid, pos, dir)
    continue_path(grid, pos, dir, path, visited_states, next_pos, next_dir)
  end

  defp continue_path(grid, pos, dir, path, visited_states, next_pos, next_dir) do
    check_bounds(out_of_bounds?(grid, next_pos), grid, pos, dir, path, visited_states, next_pos, next_dir)
  end

  defp check_bounds(true, _grid, _pos, _dir, path, visited_states, _next_pos, _next_dir), do: {path, visited_states}
  defp check_bounds(false, grid, pos, dir, path, visited_states, next_pos, next_dir) do
    walk_path_rec(
      grid,
      next_pos,
      next_dir,
      MapSet.put(path, next_pos),
      MapSet.put(visited_states, {pos, dir})
    )
  end

  defp get_next_move(grid, pos, dir) do
    front_pos = front_position(pos, dir)
    get_next_position(blocked?(grid, front_pos), grid, pos, dir, front_pos)
  end

  defp get_next_position(true, _grid, pos, dir, _front_pos), do: {pos, turn_right(dir)}
  defp get_next_position(false, _grid, _pos, dir, front_pos), do: {front_pos, dir}

  defp front_position({x, y}, :up), do: {x, y - 1}
  defp front_position({x, y}, :right), do: {x + 1, y}
  defp front_position({x, y}, :down), do: {x, y + 1}
  defp front_position({x, y}, :left), do: {x - 1, y}

  defp turn_right(dir) do
    case dir do
      :up -> :right
      :right -> :down
      :down -> :left
      :left -> :up
    end
  end

  defp blocked?(grid, {x, y}) do
    out_of_bounds?(grid, {x, y}) or
      Enum.at(grid, y, []) |> Enum.at(x, ".") == "#"
  end

  defp out_of_bounds?(grid, {x, y}) do
    y < 0 or x < 0 or
      y >= length(grid) or
      x >= length(Enum.at(grid, 0, []))
  end

  defp at_edge?(grid, {x, y}) do
    x == 0 or y == 0 or
      y == length(grid) - 1 or
      x == length(Enum.at(grid, 0)) - 1
  end

  defp visualize_path(grid, path) do
    grid
    |> Enum.with_index()
    |> Enum.map_join("\n", &visualize_row(&1, path))
    |> IO.puts()
    
    IO.puts("\nPath length: #{MapSet.size(path)}")
  end

  defp visualize_row({row, y}, path) do
    row
    |> Enum.with_index()
    |> Enum.map_join("", &visualize_cell(&1, y, path))
  end

  defp visualize_cell({cell, x}, y, path) do
    case {MapSet.member?(path, {x, y}), cell} do
      {true, _} -> "X"
      {false, "#"} -> "#"
      {false, _} -> "."
    end
  end

  defp creates_loop?(grid, start_pos, obstacle_pos) do
    # Create a new grid with the obstacle
    new_grid = add_obstacle(grid, obstacle_pos)
    
    # Walk the path and check if we hit a loop before reaching the edge
    {_, visited_states} = walk_path(new_grid, start_pos, :up)
    
    # If we have visited states but didn't reach the edge, we found a loop
    MapSet.size(visited_states) > 0 and not path_reaches_edge?(new_grid, start_pos)
  end

  defp path_reaches_edge?(grid, start_pos) do
    {path, _} = walk_path(grid, start_pos, :up)
    Enum.any?(path, fn {x, y} -> 
      x == 0 or y == 0 or
      y == length(grid) - 1 or
      x == length(Enum.at(grid, 0)) - 1
    end)
  end

  defp add_obstacle(grid, {x, y}) do
    grid
    |> Enum.with_index()
    |> Enum.map(&update_row(&1, x, y))
  end

  defp update_row({row, y}, x, target_y) when y == target_y do
    row
    |> Enum.with_index()
    |> Enum.map(&update_cell(&1, x))
  end
  defp update_row({row, _y}, _x, _target_y), do: row

  defp update_cell({_cell, x}, target_x) when x == target_x, do: "#"
  defp update_cell({cell, _x}, _target_x), do: cell
end
