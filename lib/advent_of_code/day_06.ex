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

  defp walk_path_rec(grid, pos = {_x, _y}, dir, path, visited_states) do
    # Get next position and direction based on current state
    {next_pos, next_dir} = get_next_move(grid, pos, dir)
    state = {pos, dir}

    cond do
      # If we've been in this state before, we're done
      MapSet.member?(visited_states, state) ->
        {path, visited_states}

      # If we're at the edge of the grid, we're done
      at_edge?(grid, pos) ->
        {path, visited_states}

      # If we're about to go out of bounds, we're done
      out_of_bounds?(grid, next_pos) ->
        {path, visited_states}

      true ->
        # Continue walking
        walk_path_rec(
          grid,
          next_pos,
          next_dir,
          MapSet.put(path, next_pos),
          MapSet.put(visited_states, state)
        )
    end
  end

  defp get_next_move(grid, {x, y}, dir) do
    # Calculate position in front based on current direction
    front_pos = case dir do
      :up -> {x, y - 1}
      :right -> {x + 1, y}
      :down -> {x, y + 1}
      :left -> {x - 1, y}
    end

    # Check if front position is blocked
    if blocked?(grid, front_pos) do
      # If blocked, stay in place and turn right
      {{x, y}, turn_right(dir)}
    else
      # If not blocked, move forward keeping same direction
      {front_pos, dir}
    end
  end

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
    |> Enum.map(fn {row, y} ->
      row
      |> Enum.with_index()
      |> Enum.map(fn {cell, x} ->
        cond do
          MapSet.member?(path, {x, y}) -> "X"
          cell == "#" -> "#"
          true -> "."
        end
      end)
      |> Enum.join("")
    end)
    |> Enum.join("\n")
    |> IO.puts()
    
    IO.puts("\nPath length: #{MapSet.size(path)}")
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
    |> Enum.map(fn {row, row_y} ->
      if row_y == y do
        row
        |> Enum.with_index()
        |> Enum.map(fn {cell, col_x} ->
          if col_x == x, do: "#", else: cell
        end)
      else
        row
      end
    end)
  end
end
