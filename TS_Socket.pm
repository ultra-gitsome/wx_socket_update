#############################################################################
## Name:        TS_Socket.pm
## Purpose:     Appended betterments of Wx::Socket
## Created:     23/11/2012
## Copyright:   see below
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################
#Modified from
    #############################################################################
    ## Name:        ext/socket/lib/Wx/Socket.pm
    ## Purpose:     Wx::Socket
    ## Author:      Graciliano M. P.
    ## Modified by:
    ## Created:     27/02/2003
    ## RCS-ID:      $Id: Socket.pm 2057 2007-06-18 23:03:00Z mbarbon $
    ## Copyright:   (c) 2003-2004 Graciliano M. P.
    ## Licence:     This program is free software; you can redistribute it and/or
    ##              modify it under the same terms as Perl itself
    #############################################################################
#Package name changed to prevent confusion with original socket.pm package
#CPAN Socket.pm source is nearly 10 years old but appears to function correctly
#Does not look like any further development or bug fixes have been (or will be) done
#This is meant as a local fork

package Wx::TS_Socket ;

use Wx;
use strict;

use vars qw($VERSION);

$VERSION = '0.02';

Wx::load_dll( 'net' );
Wx::wx_boot( 'Wx::Socket', $VERSION );

no strict ;
package Wx::DatagramSocket ; @ISA = qw(Wx::SocketBase) ;
package Wx::SocketClient ; @ISA = qw(Wx::SocketBase) ;
package Wx::SocketServer ; @ISA = qw(Wx::SocketBase) ;
package Wx::SocketEvent ; @ISA = qw(Wx::Event) ;
package Wx::IPaddress ; @ISA = qw(Wx::SockAddress);
package Wx::IPV4address ; @ISA = qw(Wx::IPaddress);
package Wx::IPV6address ; @ISA = qw(Wx::IPaddress);
package Wx::UNIXaddress ; @ISA = qw(Wx::SockAddress);
use strict ;

#####################
# WX::SOCKET::EVENT #
#####################

package Wx::Socket::Event ;
use Wx qw(wxSOCKET_INPUT_FLAG wxSOCKET_OUTPUT_FLAG wxSOCKET_CONNECTION_FLAG
          wxSOCKET_LOST_FLAG wxSOCKET_INPUT wxSOCKET_OUTPUT
          wxSOCKET_CONNECTION wxSOCKET_LOST) ;

my $EVTID ;

sub EVT_SOCKET($$$)            { $_[0]->Connect($_[1] , -1, &Wx::wxEVT_SOCKET , $_[2] ); }
sub EVT_SOCKET_ALL($$$)        { &MAKE_EVT('all',@_) ;}
sub EVT_SOCKET_INPUT($$$)      { &MAKE_EVT(wxSOCKET_INPUT,@_) ;}
sub EVT_SOCKET_OUTPUT($$$)     { &MAKE_EVT(wxSOCKET_OUTPUT,@_) ;}
sub EVT_SOCKET_CONNECTION($$$) { &MAKE_EVT(wxSOCKET_CONNECTION,@_) ;}
sub EVT_SOCKET_LOST($$$)       { &MAKE_EVT(wxSOCKET_LOST,@_) ;}

sub MAKE_EVT {
  my $type = shift ;
  my( $handler, $sock, $callback ) = @_;
  &ENABLE_SKEVT($sock , $handler , $callback) ;
  $sock->{_WXEVT}{SUB}{$type} = $callback ;
  if (!$sock->{_WXEVT}{CONNECT}) {
    $handler->Connect( $sock->{_WXEVT}{ID} , -1 , &Wx::wxEVT_SOCKET ,
                       sub{ &CHECK_EVT_TYPE($sock,@_) } );
    $sock->{_WXEVT}{CONNECT} = 1 ;
  }
}

sub ENABLE_SKEVT {
  my ( $sock , $parent ) = @_ ;
  if ( $sock->{_WXEVT}{ENABLE} ) { return ;}
  $sock->{_WXEVT}{ID} = ++$EVTID ;
  $sock->SetEventHandler($parent, $sock->{_WXEVT}{ID}) ;
  $sock->SetNotify(wxSOCKET_INPUT_FLAG|wxSOCKET_OUTPUT_FLAG|
                   wxSOCKET_CONNECTION_FLAG|wxSOCKET_LOST_FLAG) ;
  $sock->Notify(1) ;
  $sock->{_WXEVT}{ENABLE} = 1 ;
}

sub CHECK_EVT_TYPE {
  my ( $sock , $this , $evt ) = @_ ;
  #print "$sock\n" ;
  my $evt_type = $evt->GetSocketEvent ;
  my $sub = $sock->{_WXEVT}{SUB}{$evt_type} || $sock->{_WXEVT}{SUB}{all} ;
  if ($sub) { return &$sub($sock , $this , $evt) ;}
  return( undef ) ;
}

#######
# END #
#######

1;

__END__

=head1 NAME

Wx::Socket - wxSocket* classes

=head1 USAGE

  use Wx qw(:socket) ;
  use Wx::Event qw(EVT_SOCKET_INPUT EVT_SOCKET_LOST) ;
  use Wx::Event qw(EVT_SOCKET_CONNECTION) ;
  
  {note} 	- use Wx::Socket qw(:SocketServer :SocketBase); is/are also needed to make the SocketServer work.
			- SetFlags appears to be available under :SocketBase...
			- wxSOCKET_[...] flags may need to be qw'ed in to use them with the EVT_[...] syntax

  ##########
  # CLIENT #
  ##########

  my $sock = Wx::SocketClient->new(wxSOCKET_WAITALL);

  EVT_SOCKET_INPUT($parent , $sock , \&onInput ) ;
  EVT_SOCKET_LOST($parent , $sock , \&onClose ) ;

  $sock->Connect('localhost',5050) ;

  if (! $sock->IsConnected ) { print "ERROR\n" ;}

  sub onInput {
    my ( $sock , $this , $evt ) = @_ ;
    my $length = 123;
    my $buffer ;
    $sock->Read($buffer , 1024 , $length ) ;
  }

  ##########
  # SERVER #
  ##########

  my $sock = Wx::SocketServer->new('localhost',5050,wxSOCKET_WAITALL);

  {note} - you can also call $sock->SetFlags(wxSOCKET_[...]); to set socket flags
  
  EVT_SOCKET_CONNECTION($parent , $sock , \&onConnect ) ;

  if ( !$sock->Ok ) { print "ERROR\n" ;}

  sub onConnect {
    my ( $sock , $this , $evt ) = @_ ;
	
    #{bad term} my $client = $sock->Accept(0) ;
    #{better} 
	my $server_handle = $sock->Accept(0);

    my ($local_host,$local_port) = $server_handle->GetLocal ;
    my ($peer_host,$peer_port) = $server_handle->GetPeer ;

    $server_handle->Write("This is a data test!\n") ;
	and/or
    $server_handle->Write( $data , length($data) ) ;

	- if one time use, then close the connection...
    $server_handle->Close ;
	
	- {IMPORTANT!!!!} - if you wish to use the INPUT and OUTPUT events with the server you must tie them
		to server handle...per wxWidgets documentation (http://docs.wxwidgets.org/2.8/wx_samples.html#samplesockets)
		so...set this after "my $server_handle = $sock->Accept(0)";. Input events will then be accepted.... 
	EVT_SOCKET_INPUT($this,$server_handle,\&onInput);
		
	- {NOTE} - if you do not make the correct tie between the server handle and the event, the server will wait indefinitely 
	- {ALSO NOTE} - the input_event-to-server-tie must be made within an onConnect event
	

  }

  
=head1 METHODS

All the methods work as in wxWidgets (see the documentation).

The functions for reading data (Read, ReadMsg, Peek) take 3 arguments,
like the Perl read() function:

  ## To read the data into the variable
  $sock->Read($buffer , 1024) ;

... or ...

  ## To append data at the given offset:
  $sock->Read($buffer , 1024 , $offset ) ;

The write functions (Write, WriteMsg, Unread) can be used with
1 or 2 arguments:

  $client->Write("This is a data test!\n") ;

  $client->Write($data , $length) ;

=head1 EVENTS

The events are:

    EVT_SOCKET
    EVT_SOCKET_ALL
    EVT_SOCKET_INPUT
    EVT_SOCKET_OUTPUT
    EVT_SOCKET_CONNECTION
    EVT_SOCKET_LOST

The EVT_SOCKET works as in wxWidgets, the others are wxPerl extensions.

Note that EVT_SOCKET events of wxSocketClient and wxSocketServer
work differently than other event types.

First you need to set the event handler:

    $sock->SetEventHandler($handler, $id) ;

Then you set what types of event you want to receive:

    ## this select all.
    $sock->SetNotify(wxSOCKET_INPUT_FLAG|wxSOCKET_OUTPUT_FLAG|
                     wxSOCKET_CONNECTION_FLAG|wxSOCKET_LOST_FLAG) ;

Enable the event notification:

    $sock->Notify(1) ;

And only after this use:

    ## note that $handler must be the same that was used in
    ## SetEventHandler
    EVT_SOCKET($handler, $id , sub{...} )

To make the events easier to use, the above proccess is completed within each statement below,
so you just use the following syntax:

    EVT_SOCKET_INPUT($handler , $socket , sub{...} )
    EVT_SOCKET_OUTPUT($handler , $socket , sub{...} )
    EVT_SOCKET_CONNECTION($handler , $socket , sub{...} )
    EVT_SOCKET_LOST($handler , $socket , sub{...} )

    ## This is for the events not used yet by the above:
    EVT_SOCKET_ALL($parent , $socket , sub{...} )

This is also easier for handling more than one socket in the same time.
   Take a look in the demos. [!! good luck finding demos...vaporware for this module]

=head1 SEE ALSO

L<Wx>, The wxWxwindows documentation at L<http://www.wxwindows.org/>

=head1 AUTHOR

Graciliano M. P. <gm@virtuasites.com.br>

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut