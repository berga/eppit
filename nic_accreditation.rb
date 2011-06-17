#!/usr/bin/env ruby

require 'logger'
require 'irb'
require 'ostruct'
require File.expand_path('../lib/eppit.rb', __FILE__)

class Epp::Contact < OpenStruct ; end
class Epp::Domain < OpenStruct ; end
class Epp::Domain::NameServer < OpenStruct
  def to_h
    self
  end
end

class NicAccredSession

  def initialize
    #@uri = 'https://epp-acc1.nic.it:443'
    @uri = 'https://pub-test.nic.it:443'
    @tag = 'REGISTRAR-REG'
    @tag2 = 'REGISTRAR1-REG'
    @password = 'pippo'
    @new_password = 'pippo9999'
    @password2 = 'pluto'

    @hprefix = 'reg-test1-'
    @devmode =  true
    @ca_file = '/etc/ssl/certs/ca-certificates.crt'

    start
  end

  def start
    @epp = Epp::Session.new(
                :uri => @uri,
                :tag => @tag,
                :password => @password,
                :logger => Logger.new(STDOUT),
                :debug => true,
                :services => ['urn:ietf:params:xml:ns:contact-1.0',
                              'urn:ietf:params:xml:ns:domain-1.0'],
                :extensions => ['http://www.nic.it/ITNIC-EPP/extepp-1.0',
                                'http://www.nic.it/ITNIC-EPP/extcon-1.0',
                                'http://www.nic.it/ITNIC-EPP/extdom-1.0',
                                'urn:ietf:params:xml:ns:rgp-1.0'],
                :store_file => 'tmp/accred.store.dat',
                :xml_log_file => 'log/accred.log.xml',
                :ca_file => @ca_file,
                :session_handling => :disable)

    @epp2 = Epp::Session.new(
                :uri => @uri,
                :tag => @tag2,
                :password => @password2,
                :logger => Logger.new(STDOUT),
                :debug => true,
                :services => ['urn:ietf:params:xml:ns:contact-1.0',
                              'urn:ietf:params:xml:ns:domain-1.0'],
                :extensions => ['http://www.nic.it/ITNIC-EPP/extepp-1.0',
                                'http://www.nic.it/ITNIC-EPP/extcon-1.0',
                                'http://www.nic.it/ITNIC-EPP/extdom-1.0',
                                'urn:ietf:params:xml:ns:rgp-1.0'],
                :store_file => 'tmp/accred1.store.dat',
                :xml_log_file => 'log/accred1.log.xml',
                :ca_file => @ca_file,
                :session_handling => :disable)

    # Registrante diverso da persona fisica per il dominio test.it
    # Enti pubblici
    @aa10=Epp::Contact.new
    @aa10.statuses = []
    @aa10.nic_id = @hprefix + 'AA10'
    @aa10.name = 'Franco Franchi'
    @aa10.org = 'Ente Pubblico AX'
    @aa10.street = 'Via dei Condottieri 12'
    @aa10.city = 'Livorno'
    @aa10.sp = 'LI'
    @aa10.pc = '57100'
    @aa10.cc = 'IT'
    @aa10.voice = '+39.0586631212'
    @aa10.fax = '+39.0586663131'
    @aa10.email = 'franco.franchi@ente-ax.it'
    @aa10.auth_info_pw = '1BAR-foo'
    @aa10.consent_for_publishing = 'true'
    @aa10.registrant_nationality_code = 'IT'
    @aa10.registrant_entity_type = 5
    @aa10.registrant_reg_code = @devmode ? '02118311006' : '02118312008'

    # Registrante diverso da persona fisica per il dominio test-1.it
    # tipo società/ditta
    @bb10=Epp::Contact.new
    @bb10.nic_id = @hprefix + 'BB10'
    @bb10.name = 'Sandro Rossi'
    @bb10.org = 'Gruppo TNT S.p.A.'
    @bb10.street = 'via Tritolo 23'
    @bb10.city = 'Pisa'
    @bb10.sp = 'PI'
    @bb10.pc = '56126'
    @bb10.cc = 'IT'
    @bb10.voice = '+39.050311226'
    @bb10.fax = '+39.050268298'
    @bb10.email = 'hurtlocker@tnt.it'
    @bb10.auth_info_pw = '2fooBAR'
    @bb10.consent_for_publishing = 'true'
    @bb10.registrant_nationality_code = 'IT'
    @bb10.registrant_entity_type = 2
    @bb10.registrant_reg_code = @devmode ? '02118311006' : '12345678910'
    #@bb10.registrant_reg_code = '12345678910'

    # tech per il dominio test.it
    @cc01=Epp::Contact.new
    @cc01.nic_id = @hprefix + 'CC01'
    @cc01.name = 'Carlo Conta'
    @cc01.org = 'Unodue srl'
    @cc01.street = 'via Po 6'
    @cc01.city = 'Pisa'
    @cc01.sp = 'PI'
    @cc01.pc = '56100'
    @cc01.cc = 'IT'
    @cc01.voice = '+39.050111222'
    @cc01.fax = '+39.0503222111'
    @cc01.email = 'conta@unodue.it'
    @cc01.auth_info_pw = 'OneTwoThree'
    @cc01.consent_for_publishing = 'true'

    # admin e tech per il dominio test-1.it e admin per test.it
    @dd01=Epp::Contact.new
    @dd01.nic_id = @hprefix + 'DD01'
    @dd01.name = 'Donald Duck'
    @dd01.org = 'Warehouse Ltd'
    @dd01.street = 'Warehouse street 1'
    @dd01.city = 'London'
    @dd01.sp = 'London'
    @dd01.pc = '20010'
    @dd01.cc = 'GB'
    @dd01.voice = '+44.2079696010'
    @dd01.fax = '+44.2079696620'
    @dd01.email = 'donald@duck.uk'
    @dd01.auth_info_pw = 'Money-08'
    @dd01.consent_for_publishing = 'true'

    # Registrante persona fisica per il dominio test.it
    # persona fisica
    @il10=Epp::Contact.new
    @il10.nic_id = @hprefix + 'IL10'
    @il10.name = 'Ida Lenzi'
    @il10.org = 'Ida Lenzi'
    @il10.street = 'via San Lorenzo 11'
    @il10.city = 'Napoli'
    @il10.sp = 'NA'
    @il10.pc = '80100'
    @il10.cc = 'IT'
    @il10.voice = '+39.0811686789'
    @il10.fax = '+39.0811686789'
    @il10.email = 'ida@lenzi.it'
    @il10.auth_info_pw = 'h2o-N2'
    @il10.consent_for_publishing = 'true'
    @il10.registrant_nationality_code = 'IT'
    @il10.registrant_entity_type = 1
    @il10.registrant_reg_code = 'LNZDIA56R41F839L'

    @hh10=Epp::Contact.new
    @hh10.nic_id = @hprefix + 'HH10'
    @hh10.name = @il10.name
    @hh10.org = @il10.org
    @hh10.street = @il10.street
    @hh10.city = @il10.city
    @hh10.sp = @il10.sp
    @hh10.pc = @il10.pc
    @hh10.cc = @il10.cc
    @hh10.voice = @il10.voice
    @hh10.fax = @il10.fax
    @hh10.email = @il10.email
    @hh10.auth_info_pw = @il10.auth_info_pw
    @hh10.consent_for_publishing = @il10.consent_for_publishing
    @hh10.registrant_nationality_code = @il10.registrant_nationality_code
    @hh10.registrant_entity_type = @il10.registrant_entity_type
    @hh10.registrant_reg_code = @il10.registrant_reg_code



    @test_it=Epp::Domain.new
    @test_it.name = @hprefix + 'test.it'
    @test_it.period = 1
    @test_it.nameservers = [
      Epp::Domain::NameServer.new(:name => "ns.#{@test_it.name}", :ipv4 => '192.168.100.10'),
      Epp::Domain::NameServer.new(:name => "ns2.#{@test_it.name}", :ipv4 => '192.168.100.20'),
      Epp::Domain::NameServer.new(:name => 'ns3.foo.com') ]
    @test_it.registrant = @aa10.nic_id
    @test_it.admin_contacts = [@dd01.nic_id]
    @test_it.tech_contacts = [@cc01.nic_id]
    @test_it.auth_info_pw = 'WWW-test-it'

    @test_1_it=Epp::Domain.new
    @test_1_it.name = @hprefix + 'test-1.it'
    @test_1_it.period = 1
    @test_1_it.nameservers = [ Epp::Domain::NameServer.new(:name => 'ns1.foobar.com'),
      Epp::Domain::NameServer.new(:name => 'ns2.foobar.org') ]
    @test_1_it.registrant = @bb10.nic_id
    @test_1_it.admin_contacts = [@dd01.nic_id]
    @test_1_it.tech_contacts = [@dd01.nic_id]
    @test_1_it.auth_info_pw = 'WWWtest-1'

    nil
  end

  # Test 1: Handshake
  def test1
    puts 'Connect'
    @epp.connect
    puts '@epp2.connect'
    @epp2.connect

    puts 'Hello'
    @epp.hello

    puts "session_id is now #{@epp.cookies}"

    :ok
  end

  # Test 2: Autenticazione
  def test2
    begin
      puts '@epp.login'
      @epp.login

      puts '@epp2.login'
      @epp2.login

    rescue Epp::Session::ErrorResponse => e
      puts "Ignoring error #{e}"
    end

    :ok
  end

  # Test 3: Modifica della password
  def test3
    puts 'Logout'
    begin
      @epp.logout
    rescue Epp::Session::ErrorResponse => e
      puts "Ignoring error #{e}"
    end

    puts 'Login (with pw change)'
    begin
      @epp.login(:newpw => @new_password)
    rescue Epp::Session::ErrorResponse => e
      puts "Ignoring error #{e}"
    end

    :ok
  end

  # Test 4: Controllo della disponibilità degli identificatori dei contatti da utilizzare durante il test
  def test4
    puts "contact_check(['#{@aa10.nic_id}','#{@bb10.nic_id}','#{@cc01.nic_id}','#{@dd01.nic_id}','#{@il10.nic_id}'])"

    res = @epp.contact_check([@aa10.nic_id,@bb10.nic_id,@cc01.nic_id,@dd01.nic_id,@il10.nic_id])

    res.object.each do |k,v|
      puts "#{k}: " + (v[:avail] ? 'AVAILABLE' : 'NOT AVAILABLE')
    end

    :ok
  end

  # Test 5: Creazione dei Registranti AA10, BB10 e IL10
  def test5
    puts 'contact_create(aa10)'
    @epp.contact_create(@aa10)

    puts 'contact_create(bb10)'
    @epp.contact_create(@bb10)

    puts 'contact_create(il10)'
    @epp.contact_create(@il10)

    :ok
  end

  # Test 6: Creazione dei contatti CC01 e DD01
  def test6
    puts 'contact_create(cc01)'
    @epp.contact_create(@cc01)

    puts 'contact_create(dd01)'
    @epp.contact_create(@dd01)

    :ok
  end

  # Test 7: Aggiornamento del contatto BB10 (modifica del numero di fax)
  def test7
    puts "contact_update(#{@bb10.nic_id})"
    @epp.contact_update(@bb10.nic_id, :chg => OpenStruct.new(
        :fax => '+39.0503128298'
      )
    )

    :ok
  end

  # Test 8: Visualizzazione delle informazioni di un contatto
  def test8
    puts "contact_info('#{@bb10.nic_id}')"
    @epp.contact_info(@bb10.nic_id)

    :ok
  end

  # Test 9: Verifica della disponibilità dei domini test.it e test-1.it
  def test9
    puts "domain_check(['#{@test_it.name}', '#{@test_1_it.name}'])"
    @epp.domain_check([@test_it.name,@test_1_it.name])

    :ok
  end

  # Test 10: Creazione dei due domini test.it e test-1.it
  def test10
    puts "domain_create('#{@test_it.name}')"
    @epp.domain_create(@test_it)

    puts "domain_create('#{@test_1_it.name}')"
    @epp.domain_create(@test_1_it)

    :ok
  end

  # Test 11: Aggiunta del vincolo clientTransferProhibited al dominio test.it da parte di clientA-REG
  def test11
    puts "domain_update('#{@test_it.name}') status += clientTransferProhibited"
    @epp.domain_update(@test_it.name,
      :add => OpenStruct.new(:statuses => ['clientTransferProhibited'])
    )
    :ok
  end

  # Test 12: Visualizzazione delle informazioni del dominio test.it
  def test12
    puts "domain_info('#{@test_it.name}')"
    @test_it = @epp.domain_info(@test_it.name).object

    :ok
  end

  # Test 13: Aggiornamento del dominio test.it (rimozione di uno dei tre nameserver)
  def test13
    puts "domain_update('#{@test_it.name}') ns -= #{@test_it.nameservers[1].name}"

    @epp.domain_update(@test_it.name,:rem => OpenStruct.new(:nameservers => [Epp::Domain::NameServer.new(:name => "ns2.#{@test_it.name}")]))

    :ok
  end

  # Test 14: Modifica del Registrante del dominio test.it
  def test14
    puts "domain_update('#{@test_it.name}') #{@aa10.nic_id} => #{@il10.nic_id}, domainAuthInfo=newwwtest-it"

    @epp.domain_update(@test_it.name,
      :chg => OpenStruct.new(
        :registrant => @il10.nic_id,
        :auth_info_pw=>'newwwtest-it')
    )
    :ok
  end

  # Test 15: Richiesta di modifica del Registrar del dominio test.it da parte di clientB-REG
  def test15
    puts "@epp2.domain_transfer_request('#{@test_it.name}', 'newwwtest-it')"
    begin
      @epp2.domain_transfer_request(@test_it.name, 'newwwtest-it')
    rescue => e
      puts "Error: #{e}"
    end

    puts "domain_update('#{@test_it.name}') statuses -= clientTransferProhibited"
    @epp.domain_update(@test_it.name,
      :rem => OpenStruct.new(:statuses => ['clientTransferProhibited'])
    )

    :ok
  end

  # Test 16: Nuova richiesta di modifica del Registrar del dominio test.it da parte di clientB-REG
  def test16
    puts "@epp2.domain_transfer_request('#{@test_it.name}', 'newwwtest-it')"
    @epp2.domain_transfer_request(@test_it.name, 'newwwtest-it')

    puts "@epp2.domain_transfer_query('#{@test_it.name}', 'newwwtest-it')"
    @epp2.domain_transfer_query(@test_it.name, 'newwwtest-it')

    :ok
  end

  # Test 17: Approvazione della richiesta di modifica del Registrar del dominio test.it da parte di clientA-REG
  # ed eliminazione del messaggio di richiesta dalla coda di polling
  def test17
    puts '@epp.poll'
    poll = @epp.poll

    if !poll.msg.response.msgq
      puts "!! There should be a message in queue !!"
      return :ko
    end

    puts "@epp.domain_transfer_approve('#{@test_it.name}', { :auth_info_pw => 'newwwtest-it' })"
    @epp.domain_transfer_approve(@test_it.name, { :auth_info_pw => 'newwwtest-it' })

    puts "@epp.Acking ##{poll.msg.response.msgq.id}"
    poll = @epp.ack(poll.msg.response.msgq.id)


    # si aspetta un ack per l'ultimo messaggio
    if !poll.msg.response.msgq
      puts "!! There should be a message in queue !!"
      return :ko
    end

    puts "@epp2.Acking ##{poll.msg.response.msgq.id}"
    @epp.ack poll.msg.response.msgq.id

    :ok
  end

  # Test 18: Modifica dell'authInfo del dominio test.it da parte del nuovo Registrar clientB-REG
  def test18
    puts "@epp2.domain_update(#{@test_it.name})"
    @epp2.domain_update(@test_it.name,
      :chg => OpenStruct.new(
        :auth_info_pw=>'BB-29-IT')
    )

    :ok
  end

  # Test 19: Richiesta di modifica del Registrante contestuale ad una modifica del Registrar per il dominio
  # test-1.it da parte di clientB-REG
  def test19
    puts "@epp2.contact_create('#{@hh10.nic_id}', '#{@test_1_it.auth_info_pw}')"
    @epp2.contact_create(@hh10)

    puts "@epp2.domain_transfer_request('#{@test_1_it.name}')"
    @epp2.domain_transfer_request(@test_1_it.name, @test_1_it.auth_info_pw,
      { :new_registrant => @hh10.nic_id,
        :new_auth_info_pw => 'HAC6-007'}
    )

    :ok
  end

  # Test 20: Approvazione della richiesta di modifica del Registrante e del Registrar per il dominio test-1.it da
  # parte di clientA-REG
  def test20
    puts '@epp.poll'
    poll = @epp.poll

    if !poll.msg.response.msgq
      puts "!! There should be a message in queue !!"
      return :ko
    end

    puts "domain_transfer_approve('#{@test_1_it.name}', 'WWWtest-1')"
    @epp.domain_transfer_approve(@test_1_it.name, :auth_info_pw => 'WWWtest-1')

    :ok
  end

  # Test 21: Aggiunta del vincolo clientUpdateProhibited al dominio test-1.it da parte di clientB-REG
  def test21
    puts "@epp2.domain_update('#{@test_1_it.name}') statuses += clientUpdateProhibited"
    @epp2.domain_update(@test_1_it.name, :add => OpenStruct.new(
        :statuses => ['clientUpdateProhibited']
      )
    )

    puts "@epp2.domain_info('#{@test_1_it.name}')"
    @epp2.domain_info(@test_1_it.name)

    :ok
  end

  # Test 22: Cancellazione del dominio test-1.it da parte del Registrar clientB-REG
  def test22
    puts "@epp2.domain_delete('#{@test_1_it.name}')"
    @epp2.domain_delete(@test_1_it.name)

    puts "@epp2.domain_info('#{@test_1_it.name}')"
    @epp2.domain_info(@test_1_it.name)

    :ok
  end

  # Test 23: Ripristino del dominio test-1.it da parte del Registrar clientB-REG
  def test23
    puts "@epp2.domain_undelete('#{@test_1_it.name}')"
    begin
      @epp2.domain_undelete(@test_1_it.name)
    rescue => e
      puts "Error: #{e}"
    end

    puts "@epp2.domain_update('#{@test_1_it.name}') statuses -= clientUpdateProhibited"
    @epp2.domain_update(@test_1_it.name, :rem => OpenStruct.new(
        :statuses => ['clientUpdateProhibited']
      )
    )

    puts "@epp2.domain_undelete('#{@test_1_it.name}')"
    @epp2.domain_undelete(@test_1_it.name)

    :ok
  end

  # Test 24: Cancellazione del Registrante AA10 da parte del Registrar clientA-REG
  def test24
    puts "@epp.contact_delete('#{@aa10.nic_id}')"
    @epp.contact_delete(@aa10.nic_id)

    puts "@epp.contact_check(['#{@aa10.nic_id}'])"
    @epp.contact_check([@aa10.nic_id])

    :ok
  end


  def test_poll
    puts '@epp.poll'
    poll = @epp.poll

    if poll.msg.response.msgq
      puts "Acking ##{poll.msg.response.msgq.id}"
      @epp.ack poll.msg.response.msgq.id
    else
      puts "!! There should be a message in queue !!"
      return :ko
    end
  end

  def runtest(num)
    puts "Running test #{num}"
    res = send("test#{num}")

    if res == :ko
      puts 'TEST FAILED!'
    end

    puts ''
    res
  end

  def all
    puts "Starting tests with session_id=#{@epp.cookies}"

    @test_its.each do |i|
      res = runtest i

      break if res == :ko
    end
  end

  def prefix(val)
    @hprefix = val
    start
  end

  def print_usage
    puts 'NIC.it accreditation tester'
    puts ' current parameters:'
    puts "   @uri = #{@uri}"
    puts "   @tag = #{@tag}"
    puts "   @password = #{@password}"
    puts "   @new_password = #{@new_password}"
    puts "   @tag2 = #{@tag2}"
    puts "   @password2 = #{@password2}"
    puts "   @devmode = #{@devmode}"
    puts "   @hprefix = #{@hprefix}"
    puts "   @ca_file = #{@ca_file}"
    puts ''
    puts 'Available commands:'
    puts '  testX   : run test "X"'
    puts '  all     : run all tests'
    puts '  prefix  : set prefix prepended to nic handles and domain names, for development'
    puts '  start   : initialize all object with new parameters'
    puts ''
    puts 'Variables:'
    puts '  @epp    : EPP session as registry 1'
    puts '  @epp2   : EPP session as registry 2'
  end
end

module IRB # :nodoc:
  def self.start_session(binding)
    unless @__initialized
      args = ARGV
      ARGV.replace(ARGV.dup)
      IRB.setup(nil)
      ARGV.replace(args)
      @__initialized = true
    end

    workspace = WorkSpace.new(binding)

    irb = Irb.new(workspace)

    @CONF[:IRB_RC].call(irb.context) if @CONF[:IRB_RC]
    @CONF[:MAIN_CONTEXT] = irb.context

    catch(:IRB_EXIT) do
      irb.eval_input
    end
  end
end

sess = NicAccredSession.new

sess.print_usage

IRB.start_session(sess)

