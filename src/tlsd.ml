open Core.Std
open Async.Std
  
let ssl_blocks cert buffer r w dest_host dest_port =
  let net_to_ssl = Reader.pipe r in
  let ssl_to_net = Writer.pipe w in
  let app_to_ssl, app_wr = Pipe.create () in
  let app_rd, ssl_to_app = Pipe.create () in
  let th = Async_ssl.Ssl.server
      ~crt_file:cert
      ~key_file:cert
      ~app_to_ssl
      ~ssl_to_app
      ~net_to_ssl
      ~ssl_to_net ()
  in
  Deferred.Or_error.(th >>= fun x -> 
    let open Async_ssl.Ssl in
    let v = Connection.version x in
    let str = 
      match v with
      | Version.Sslv23 -> "sslv23"
      | Version.Sslv3 -> "sslv3"
      | Version.Tlsv1 -> "tlsv1"
      | Version.Tlsv1_1 -> "tlsv1_1"
      | Version.Tlsv1_2 -> "tlsv1_2"
    in
    return ()) >>= fun _ ->
  let th = 
    Tcp.connect (Tcp.to_host_and_port dest_host dest_port)
    >>= fun (_, rd, wr) ->
    Deferred.all_ignore
      [ Pipe.transfer_id app_rd (Writer.pipe wr);
        Pipe.transfer_id (Reader.pipe rd) app_wr ]
  in th

(** Starts a TCP server, which listens on the specified port, invoking
    copy_blocks every time a client connects. *)
let run cert localport dest_host dest_port =
  let host_and_port =
    Tcp.Server.create
      ~on_handler_error:`Raise
      (Tcp.on_port localport)
      (fun _addr r w ->
         let buffer = String.create (16 * 1024) in
         ssl_blocks cert buffer r w dest_host dest_port)
  in
  ignore (host_and_port : (Socket.Address.Inet.t, int) Tcp.Server.t Deferred.t);
  never_returns (Scheduler.go ())

let description = String.concat ~sep:" " [
    "A TLS wrapping/unwrapping daemon"
  ]

open Cmdliner

let cert =
  let doc = "Certificate file" in
  Arg.(value & opt file "/dev/null" & info ["c"; "cert"] ~doc)

let host =
  let doc = "Host to proxy to" in
  Arg.(value & opt string "localhost" & info ["h"; "host"] ~doc)

let port =
  let doc = "Port to proxy to" in
  Arg.(value & opt int 80 & info ["p"; "port"] ~doc)

let localport = 
  let doc = "Local port to listen on" in
  Arg.(value & opt int 443 & info ["l"; "localport"] ~doc)

let info =
  let doc = "Wrap an existing service in TLS" in
  let man = [ `S "BUGS"; `P "Report bugs on the github page."; ] in
  Term.info "tlsd" ~version:"0.0.1" ~doc ~man

let _ =
  let tlsd_t = Term.(pure run $ cert $ localport $ host $ port) in  
  Term.eval (tlsd_t, info)

