(*
 * Copyright (C) 2015 Citrix Systems Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation; version 2.1 only. with the special
 * exception on linking described in file LICENSE.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *)

open Core.Std
open Async.Std
open Async_ssl.Std

let ssl_connect net_to_ssl ssl_to_net =
  let net_to_ssl = Reader.pipe net_to_ssl in
  let ssl_to_net = Writer.pipe ssl_to_net in
  let client = Ssl.client
      ~app_to_ssl:(Reader.pipe (Reader.of_in_channel stdin Fd.Kind.Char))
      ~ssl_to_app:(Writer.pipe (Writer.of_out_channel stdout Fd.Kind.Char))
      ~net_to_ssl ~ssl_to_net () in
  let open Deferred.Or_error in
  client >>= fun _con -> Async_ssl.Ssl.Connection.closed _con >>= fun () -> exit 0; return ()

let connect host port =
  let th =
    Tcp.connect (Tcp.to_host_and_port host port)
    >>= fun (_, rd, wr) ->
    ssl_connect rd wr
  in
  never_returns (Scheduler.go ())
  
open Cmdliner

let host =
  let doc = "Hostname to connect to" in
  Arg.(required & opt (some string) None & info ["h"; "host"] ~doc)

let port =
  let doc = "Port to connect to" in
  Arg.(value & opt int 443 & info ["p"; "port"] ~doc)

let info =
  let doc = "Connect using TLS to a server" in
  let man = [ `S "BUGS"; `P "Report bugs on the github page.";] in
  Term.info "tlsc" ~version:"0.0.1" ~doc ~man

let _ =
  let tlsc_t = Term.(pure connect $ host $ port) in
  Term.eval (tlsc_t, info)
  
    
