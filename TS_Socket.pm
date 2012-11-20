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

=head1 USAGE (Part 2)

	## 
	## the following is some rough documentation of how I used the wx::socket's module
	## it may not be structed as intended, but it does seem to work
	## i have borrowed other comments from other documentation, my apologies if I did not properly cite your POD.
	##
	
	
	# my main caller method:
	# Note, that I am using the Wx server as the end-point display of 2 or more POE data transfer servers
	# thus, I have a data handling class/object that takes care of the standardized data methods and server config

	#!perl
	use strict;
	use warnings;

	use Wx;
	use MySys::DisplayApp;
	use MySys::Display::DFrame;
	use MySys::Display::FDisplay;
	use MySys::DataManager;
	@MySys::Display::FDisplay::ISA = qw(MySys::Display);

	use IO::Socket;
	use IO::Socket::INET;
	use Socket;

	use POE qw(Wheel::SocketFactory
	  Wheel::ReadWrite
	  Driver::SysRW
	  Filter::Reference
	);

	## config globals...

	package main;
	my($app) = DisplayApp->new();
	$app->MainLoop();

=head1 USAGE (Part 3)

	# the DisplayApp
	# my primary data handling class/object is created here

	package DisplayApp;
	#######################################
	#
	#######################################
	use strict;
	use warnings;
	use vars qw(@ISA);
	@ISA = qw(Wx::App);
	@MySys::Display::FDisplay::ISA = qw(MySys::Display);
	$my_server_address = '127.0.0.1';
	$my_server_port = 60000;
	
	sub OnInit {
		my($this) = @_;
		
		$data_handler = DataManager->new();

		# Note, that the $data_handler is an extra argument tucked onto the ->new() statement :-)
		my($frame) = DFrame->new( undef, -1, "MySys",undef,undef,undef,undef,$data_handler);

		$frame->init($data_handler,$my_server_address,$my_server_port);
		
		#   set frame to be visible..
		#   Setting to 0 hides the frame.
		$frame->Show(1);
		
		# Not needed by my display process...
		#$this->SetTopWindow($frame);

		# if OnInit doesn't return true, the application exits immediately.
		return 1;
	}

	1;

=head1 USAGE (Part 4)

	# the frame (class)
	# the primary event configuration and control center
	
	package PFrame;
	#######################################
	#
	#######################################
	#   This package overrides Wx::Frame, and allows us to put controls
	#   in the frame.
	#
	use strict;
	use warnings;
	use vars qw(@ISA);
	@ISA = qw(Wx::Frame);
	@MySys::Display::FDisplay::ISA = qw(MySys::Display);
  
	#
	#  pick the constants you need
	# :socket must be brought in to declare a new socket
	#
	use Wx qw(:id
			  :toolbar
			  :socket
			  wxNullBitmap
			  wxDefaultPosition
			  wxDefaultSize
			  wxDefaultPosition
			  wxDefaultSize
			  wxNullBitmap
			  wxTB_VERTICAL
			  wxSIZE
			  wxSOCKET_WAITALL
			  wxTE_MULTILINE
			  wxBITMAP_TYPE_BMP
	);

	#	NOTES, by others...
	#   Wx::Events allows us to attach events to user's actions.
	#   EVT_SIZE for resizing a window
	#   EVT_MENU for selecting a menu item
	#   EVT_COMBOBOX for selecting a combo box item
	#   EVT_TOOL_ENTER for selecting toolbar items
	#
	#  the socket events must be declared to make the events work...
	use Wx::Event qw(EVT_SIZE
					 EVT_MENU
					 EVT_SOCKET_CONNECTION
					 EVT_SOCKET_INPUT
					 EVT_SOCKET_OUTPUT
					 EVT_SOCKET_LOST
					 EVT_IDLE
					 EVT_COMBOBOX
					 EVT_UPDATE_UI
					 EVT_TOOL_ENTER
	);
	
	#  declare use of Wx::Socket per USAGE part 1
	#  :SocketServer and :SocketBase are needed for socket calls to work
	use Wx::Socket qw(:SocketServer
						:SocketBase
	#					wxSOCKET_WAITALL
						wxSOCKET_NOWAIT
						SetFlags
						);

	## kludgy, but the pointers to the two main data objects are stored here 
	## so they can be accessed by all methods
	my $display_obj = undef;
	my $data_manager_obj = undef;

	## YAML is used for the data transfer protocol
	## the final data packet gets filtered into a hash variable,
	## that is then loaded into the data_manager
	my $yaml = 'YAML';
	my $ref_filter = POE::Filter::Reference->new($yaml);

	## The only functional socket flag under windows appears to be wxSOCKET_NOWAIT
	## This was not investigated fully but the other flags appear to block the data input
	## (likely because the Wx server does not know that it is finished)
	## so wxSOCKET_NOWAIT returns the buffer immediately and the data packet is built in a local method - like a buffer container.
	## FYI, the POE Yaml filter will not work without a complete data packet.
	my $buffer_container = '';
	my $buffer_processed = 0;

	sub new {
		my( $class ) = shift;
		my @class_params = @_;

		## inputs to window/frame creation
		## cannot use the class_params in their 'raw' hash  because we need to retrieve the $data_handler object
		my @super_params = ();
		my $data_handler = undef;
		if($class_params[7]=~/HASH/i) {
			## this is the data handler object
			$data_handler = $class_params[7];
		}
		for(my $c=0; $c<7; $c++) {
		
			## stuff left out here ...
			## a config file is opened to load window parameters
			## ...your method may vary
			$super_params[$c] = $class_params[$c];
		}

		# the frame object is created with the SUPER params
		my( $this ) = $class->SUPER::new( @super_params );

		## store the data handler
		$this->_data_handler($data_handler);

		return $this;
	}

	sub init {
		## still using 'this'....
		my $this = shift;
		my $data_handler = shift; ## somewhat redundant
		my $my_server_address = shift;
		my $my_server_port = shift;
	
		# Create a new Display object, and store it locally
		my $display = FDisplay->new( $this );
		$this->_display_handle($display);

		## the display uses the Wx::Grid package...mostly handy and relatively easy to use
		## I use three steps: 1) create the grid in the frame window, 2) format the grid,
		## and, 3) format the cells in the grid. That just makes it less messy for me.
		$display->start_grid($data_handler,$this);
		$display->format_grid($data_handler);
		$display->format_cells($data_handler);
	
		## create the socket object, per the USAGE part 1
		my $sock = Wx::SocketServer->new($my_server_address,$my_server_port);
		
		## I set the ..._NOWAIT flag separately...preference only
		## As noted above - this is the only flag that seems to actually allow the GUI display to show incoming data
		$sock->SetFlags(wxSOCKET_NOWAIT);

		## make a socket event tie to the 'onConnect' method
		## Note, that attempting to tie an input event to the 'onInput' method will not work within the 'init' method...
		EVT_SOCKET_CONNECTION($this,$sock,\&onConnect);

		# do a socket check...
		if(!$sock->Ok) { print "\nERROR! Not able to make socket connection on[$my_server_address : $my_server_port]\n\n"; }
	
		return 1;
	}
	## helper methods
	sub _display_handle {
		## using perlish 'self' now
		my $self = shift;
		if(@_) { $display_obj = shift; }
		return $display_obj;
	}
	sub _data_handler {
		my $self = shift;
		if(@_) { $data_manager_obj = shift; }
		return $data_manager_obj;
	}
	sub show_data {
		my $self = shift;
		my $data_handler = shift;
		
		## data is 'stacked' inside the data-handler object so this is sent to the display object
		## first, fetch the display object
		my $display = $self->_display_handle();
		
		$display->show_data($data_handler);
		
		return 1;
	}

	sub onConnect {
		## 'this' is back....
		## this method is mostly the same as under USAGE part 1
		my ($sock, $this, $evt) = @_;
		my $server_handle = $sock->Accept(0);

		## !! Set here, the tie between the socket server INPUT-event and the 'onInput' method
		EVT_SOCKET_INPUT($this,$server_handle,\&onInput);

		## check and/or use...
		my ($peer_host, $peer_port) = $server_handle->GetPeer;

		## a hole thru the encapsulation...
		my $data_handler = $this->_data_handler();

		## my data transfer process requires a 'welcome' connection trigger
		my $send = {};
		$send->{state} = "welcome";
		$send->{mess} = "send me data";
	
		####
		## package the send (info request) hash array into a Yaml stream - formatted for a POE server
		## this method is located in the data_handler object...your coding may vary.
		####
		my $req_send = $data_handler->format_POE_Yaml_send($send);
	
		####
		## write the info request data package to the socket
		####
		## make a Write() on the server handle to trigger data sending
		$server_handle->Write( $req_send, length($req_send));
	
		return;
	}
	sub onInput {
		## 'this' again...
		my ($server_handle, $this, $evt) = @_;

		my $data_handler = $this->_data_handler();

		my $done = $this->read_data_onto_stack($data_handler,$server_handle);

		if($done) {
			## to use for packet confirm...
			my $send = {};
			$send->{state} = "confirm";
			$send->{mess} = "send me more";

			my $req_send = $node->format_POE_Yaml_send($send);

			$server_handle->Write( $req_send, length($req_send));
			$buffer_processed = 0;
		}
	
		return;
	}
	sub read_data_onto_stack {
		my $self = shift;
		my $data_handler = shift;
		my $server_handle = shift;
	
		## there are probably better ways to structure this data stacking process
		## the following is just my example - which I understand :-)
		## the peek'ing may not be necessary
		## the buffer reading process in the SocketServer appears to augment the 
		## input event Read's with an extra input event that is zero length.
		
		my $buffer_empty = 0;
		$server_handle->Peek(my $check, 1024);
		if(length($check) < 1024) { $buffer_empty = 1; }
	
		while ($server_handle->Read(my $buffer, 1024)) {
			## small method to add new data to buffer container
			$self->join_buffer($buffer);
		}

		my $ct = 0;
		if($buffer_empty && length($buffer_cont)) {
			## process the entire data packet onto a data_handler stack
			$ct = $self->process_packet($data_handler);
			$buffer_empty = 0;
		}
		return $ct;
	}

	1;

=head1 USAGE (Part 4)

	# the display (class)
	
	package FDisplay;
	#######################################
	#
	#
	use strict;
	use warnings;
	my $carp_for_testing = 1;

	use vars qw(@ISA);	
	use Wx qw(:everything);

	## declare wx-grid to use to structure the on-screen tabular data
	use Wx::Grid;
	@ISA = qw(Wx::Grid);

	## standard perl object declaration...
	sub new {
		my $proto = shift;
		my $class = ref($proto) || $proto;
		my $self  = {};
		$self->{NAME}     = undef;
		$self->{BASE_DIR} = "c:/MyApp/";
		$self->{CONFIG_FILE} = 'sDisplayConfigure.yml';
		$self->{CONFIG_DIR} = 'server_conf/';
		$self->{DISPLAY_SETTINGS} = {};
		$self->{DISPLAY_GRID} = undef;
		bless ($self, $class);
		return $self;
	}
	sub _grid_handle {
		my $self = shift;
		if(@_) { $self->{DISPLAY_GRID} = shift; }
		return $self->{DISPLAY_GRID};
	}
	sub start_grid {
		my $self = shift;
		my $data_handler = shift;
		my $winframe = shift;
		
		## my method to retrieve display config settings :)
		my $display_settings = $data_handler->display_settings();

		## defaults
		... $rows, $cols ...
		
		## set settings from $display_settings
		....
		
		my $grid = Wx::Grid->new(
			$winframe, 						#parent
			-1, 							#id
			[$start_pos_x, $start_pos_y], 	#position
			[$dim_x, $dim_y] 				#dimensions
		);
		
		## store handle to grid object
		$self->_grid_handle($grid);
		
		$grid->CreateGrid(
			$rows, #rows
			$cols #cols
		);
		return 1;
	}
	sub format_grid {
		my $self = shift;
		my $data_handler = shift;
		my $grid = $self->_grid_handle();

		my $display_settings = $data_handler->display_settings();

		## defaults
		... $rows, $cols ...
		
		## set settings from $display_settings
		....
		
		## sample of possible grid tools
		my $font = Wx::Font->new($font_size, wxFONTFAMILY_ROMAN, wxNORMAL, wxNORMAL);
		
		$grid->SetColLabelSize($head_col_ht);
		$grid->SetRowLabelSize($row_label_wd);
		$grid->SetLabelFont($font);
		$grid->SetDefaultCellAlignment(wxALIGN_CENTRE,wxALIGN_CENTRE);

		return 1;
	}

	sub format_cells {
		my $self = shift;
		my $data_handler = shift;
		my $grid = $self->_grid_handle();

		my $display_settings = $data_handler->display_settings();

		## defaults
		... $rows, $cols ...
		
		## set settings from $display_settings
		....

		## sample of possible grid tools
		my $font = Wx::Font->new($font_size, wxFONTFAMILY_SWISS, wxNORMAL, wxNORMAL);

		$grid->SetDefaultRowSize($row_ht,1);
		$grid->SetDefaultCellFont($font);
		$grid->SetRowMinimalHeight(0,$first_row_ht);
		$grid->SetRowSize(0,$first_row_ht);
		return 1;
	}
	sub show_data {
		my $self = shift;
		my $data_handler = shift;
		my $grid = $self->_grid_handle();

		my $display_settings = $data_handler->display_settings();

		## defaults
		... $rows, $cols ...
		
		## set settings from $display_settings
		....

		## get some stacked data...and/or keys
		my $d_stack = $data_handler->display_data();
		my $key_stack = $data_handler->key_control();

		## sample of possible grid tools
		my $font = Wx::Font->new($font_size, wxFONTFAMILY_SWISS, wxNORMAL, wxNORMAL);

		## loop rows and columns (not shown)
		$grid->SetCellValue($s, $col, $cell_value);
		$grid->SetCellAlignment($s,$col,wxALIGN_CENTRE,wxALIGN_CENTRE);
		$grid->SetRowSize($first_row_ht,1);
		if($s) {
			$grid->SetCellFont($s,$col,$font);
		} else {
			$grid->SetCellFont($s,$col,$first_font);
		}

		$grid->SetCellTextColour(2, 0, Wx::Colour->new(255,0,0));
		$grid->SetCellBackgroundColour(2, 0, Wx::Colour->new(255,255,128));
		$grid->SetColFormatFloat(0, 0, 2);
		$grid->SetReadOnly(1, 0);
		return 1;
	}
	
	
=head1 METHODS

All the methods work as in wxWidgets (see the documentation). [Note that the wxWidgets code has been actively developed
and this module has been static since 2003. But this package only uses the main function of wxsocket...so it works if you 
only need a simple socket listener.]


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