open Matplotlib

module Array = struct
  include Array

  let float_mean arr =
    let rec aux idx mean =
      match idx < Array.length arr with
      | false -> mean
      | true ->
          let count = float idx +. 1. in
          let mean = mean -. (mean /. count) +. (arr.(idx) /. count) in
          aux (idx + 1) mean in
    aux 0 0.

  let float_std ?mean arr =
    let mean = match mean with None -> float_mean arr | Some mean -> mean in
    let rec aux idx std =
      match idx < Array.length arr with
      | false -> std
      | true ->
          let count = float idx +. 1. in
          let std =
            std -. (std /. count) +. (((arr.(idx) -. mean) ** 2.) /. count)
          in
          aux (idx + 1) std in
    let n = float @@ Array.length arr in
    sqrt (n /. (n -. 1.) *. aux 0 0.)
end

let alg_batch batch_size make_bandit make_alg =
  Array.init batch_size (fun _ -> make_alg (make_bandit ()))

let get_regrets npoints step algs =
  Array.iter (fun alg -> alg#reset) algs ;
  let regret_after_pull (alg : < pull: ?ntimes:int -> unit -> float ; .. >) =
    alg#pull ~ntimes:step () in
  Array.init npoints (fun _ ->
      Array.map (fun alg -> regret_after_pull alg) algs)

module Pyplot = struct
  include Pyplot

  let plot_mean_std ?(linewidth = 2.) ?(alpha = 0.3) ?label x ys =
    let means = Array.map Array.float_mean ys in
    let stds = Array.map Array.float_std ys in
    ( match label with
    | None -> Pyplot.plot ~linewidth ~xs:x means
    | Some label -> Pyplot.plot ~linewidth ~label ~xs:x means ) ;
    Pyplot.fill_between ~alpha x
      (Array.map2 ( -. ) means stds)
      (Array.map2 ( +. ) means stds)
end

let set_figure_settings ?(grid = true) ?xlabel ?ylabel ?labels ?(legend = true)
    () =
  Pyplot.grid grid ;
  let set_label axis label =
    match label with
    | None -> ()
    | Some label -> (
      match axis with `x -> Pyplot.xlabel label | `y -> Pyplot.ylabel label )
  in
  set_label `x xlabel ;
  set_label `y ylabel ;
  if legend then
    match labels with
    | None -> Pyplot.legend ()
    | Some labels -> Pyplot.legend ~labels ()
