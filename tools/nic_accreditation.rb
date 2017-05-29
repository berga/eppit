#!/usr/bin/env ruby

require 'logger'
require 'pry'
require File.expand_path('../lib/eppit/session.rb', __FILE__)

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
    @epp = Eppit::Session.new(
    :uri => @uri,
    :tag => @tag,
    :password => @password,
    :logger => Logger.new(STDOUT),
    :debug => true,
    :services => [
      'urn:ietf:params:xml:ns:contact-1.0',
      'urn:ietf:params:xml:ns:domain-1.0'
    ],
    :extensions => [
      'http://www.nic.it/ITNIC-EPP/extepp-1.0',
      'http://www.nic.it/ITNIC-EPP/extcon-1.0',
      'http://www.nic.it/ITNIC-EPP/extdom-1.0',
      'urn:ietf:params:xml:ns:rgp-1.0'
    ],
    :store_file => 'tmp/accred.store.dat',
    :xml_log_file => 'log/accred.log.xml',
    :ca_file => @ca_file,
    :session_handling => :disable)

    @epp2 = Eppit::Session.new(
      :uri => @uri,
      :tag => @tag2,
      :password => @password2,
      :logger => Logger.new(STDOUT),
      :debug => true,
      :services => [
        'urn:ietf:params:xml:ns:contact-1.0',
        'urn:ietf:params:xml:ns:domain-1.0'
      ],
      :extensions => [
        'http://www.nic.it/ITNIC-EPP/extepp-1.0',
        'http://www.nic.it/ITNIC-EPP/extcon-1.0',
        'http://www.nic.it/ITNIC-EPP/extdom-1.0',
        'urn:ietf:params:xml:ns:rgp-1.0'
      ],
      :store_file => 'tmp/accred1.store.dat',
      :xml_log_file => 'log/accred1.log.xml',
      :ca_file => @ca_file,
      :session_handling => :disable)

    @aa100=Eppit::Contact.new
    @aa100.nic_id = @hprefix + 'AA100'
    @aa100.name = 'Arnoldo Asso'
    @aa100.org = 'Arnoldo Asso'
    @aa100.street = 'viale Garibaldi 23'
    @aa100.city = 'Pisa'
    @aa100.sp = 'PI'
    @aa100.pc = '56100'
    @aa100.cc = 'IT'
    @aa100.voice = '+39.050112112'
    @aa100.fax = '+39.050113113'
    @aa100.email = 'arnoldo@asso.it'
    @aa100.auth_info_pw = '1BAR-foo'
    @aa100.consent_for_publishing = 'true'
    @aa100.registrant_nationality_code = 'IT'
    @aa100.registrant_entity_type = 1
    @aa100.registrant_reg_code = 'SSARLD69A01G702E'

    @bb100=Eppit::Contact.new
    @bb100.nic_id = @hprefix + 'BB100'
    @bb100.name = 'Carlo Verdi'
    @bb100.org = 'Banda Bassotti S.p.A.'
    @bb100.street = 'via Deposito 23'
    @bb100.city = 'Livorno'
    @bb100.sp = 'LI'
    @bb100.pc = '57100'
    @bb100.cc = 'IT'
    @bb100.voice = '+39.0586313131'
    @bb100.fax = '+39.0586313313'
    @bb100.email = 'rossi@bandabassotti.it'
    @bb100.auth_info_pw = '2fooBAR'
    @bb100.consent_for_publishing = 'true'
    @bb100.registrant_nationality_code = 'IT'
    @bb100.registrant_entity_type = 2
    @bb100.registrant_reg_code = @devmode ? '02118311006' : '12345678910'

    @ee100=Eppit::Contact.new
    @ee100.nic_id = @hprefix + 'EE100'
    @ee100.name = 'Mario Lenzi'
    @ee100.org = 'Associazione Energia Economica'
    @ee100.street = 'via Energy 10'
    @ee100.city = 'Acireale'
    @ee100.sp = 'CT'
    @ee100.pc = '95094'
    @ee100.cc = 'IT'
    @ee100.voice = '+39.095999999'
    @ee100.fax = '+39.095888888'
    @ee100.email = 'info@saveenergy.it'
    @ee100.auth_info_pw = 'h2o-N2'
    @ee100.consent_for_publishing = 'true'
    @ee100.registrant_nationality_code = 'IT'
    @ee100.registrant_entity_type = 4
    @ee100.registrant_reg_code = '33300022200'

    @cc001=Eppit::Contact.new
    @cc001.nic_id = @hprefix + 'CC001'
    @cc001.name = 'Corrado Camel'
    @cc001.org = 'Minerali srl'
    @cc001.street = 'viale Arno 11'
    @cc001.city = 'Pisa'
    @cc001.sp = 'PI'
    @cc001.pc = '56100'
    @cc001.cc = 'IT'
    @cc001.voice = '+39.050111222'
    @cc001.fax = '+39.0503222111'
    @cc001.email = 'glass@mineralwater.it'
    @cc001.auth_info_pw = 'Water-2008'
    @cc001.consent_for_publishing = 'true'

    @dd001=Eppit::Contact.new
    @dd001.nic_id = @hprefix + 'DD001'
    @dd001.name = 'Donald Duck'
    @dd001.org = 'Warehouse Ltd'
    @dd001.street = 'Warehouse street 1'
    @dd001.city = 'London'
    @dd001.sp = 'London'
    @dd001.pc = '20010'
    @dd001.cc = 'GB'
    @dd001.voice = '+44.2079696010'
    @dd001.fax = '+44.2079696620'
    @dd001.email = 'donald@duck.uk'
    @dd001.auth_info_pw = 'Money-08'
    @dd001.consent_for_publishing = 'true'

    @hh100=Eppit::Contact.new
    @hh100.nic_id = @hprefix + 'HH100'
    @hh100.name = 'Mario Lenzi'
    @hh100.org = 'Associazione Energia Economica'
    @hh100.street = 'via Energy 10'
    @hh100.city = 'Acireale'
    @hh100.sp = 'CT'
    @hh100.pc = '95094'
    @hh100.cc = 'IT'
    @hh100.voice = '+39.095999999'
    @hh100.fax = '+39.095888888'
    @hh100.email = 'info@saveenergy.it'
    @hh100.auth_info_pw = 'h2o-N2'
    @hh100.consent_for_publishing = 'true'
    @hh100.registrant_nationality_code = 'IT'
    @hh100.registrant_entity_type = 4
    @hh100.registrant_reg_code = '33300022200'

    @test1=Eppit::Domain.new
    @test1.name = @hprefix + 'test1.it'
    @test1.period = 1
    @test1.nameservers = [ Eppit::Domain::NameServer.new(:name => 'ns1.test1.it', :ipv4 => '192.168.10.100'),
                           Eppit::Domain::NameServer.new(:name => 'ns2.test1.it', :ipv4 => '192.168.11.200') ]
    @test1.registrant = @hprefix + 'AA100'
    @test1.admin_contacts = [@hprefix + 'AA100']
    @test1.tech_contacts = [@hprefix + 'CC001']
    @test1.auth_info_pw = 'WWWtest-it'

    @testone=Eppit::Domain.new
    @testone.name = @hprefix + 'test-one.it'
    @testone.period = 1
    @testone.nameservers = [ Eppit::Domain::NameServer.new(:name => 'ns1.foo.com'),
                             Eppit::Domain::NameServer.new(:name => 'ns2.bar.com') ]
    @testone.registrant = @hprefix + 'BB100'
    @testone.admin_contacts = [@hprefix + 'DD001']
    @testone.tech_contacts = [@hprefix + 'DD001']
    @testone.auth_info_pw = 'WWWtest-one'

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

    rescue Eppit::Session::ErrorResponse => e
      puts "Ignoring error #{e}"
    end

    :ok
  end

  # Test 3: Modifica della password
  def test3
    puts 'Logout'
    begin
      @epp.logout
    rescue Eppit::Session::ErrorResponse => e
      puts "Ignoring error #{e}"
    end

    puts 'Login (with pw change)'
    begin
      @epp.login(:newpw => @new_password)
    rescue Eppit::Session::ErrorResponse => e
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


    @test1.snapshot
    @test1.nameservers.reject! { |ns| ns.name == 'ns2.test1.it' }
    @test1.nameservers << Eppit::Domain::NameServer.new(:name => 'ns2.head1.com')


    :ok
  end

  # Test 14: Modifica del Registrante del dominio test.it
  def test14
    puts "domain_update('#{@test_it.name}') #{@aa10.nic_id} => #{@il10.nic_id}, domainAuthInfo=newwwtest-it"

    puts 'domain_update(test1)'
    @epp.domain_update(@test1)

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

sess.pry

