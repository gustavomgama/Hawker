profile = HawkerProfile.instance

if Rails.env.local?
  profile.go_online!

  stops = [
    { phone: "+5511990000001", name: "Ana Prado", address: "Rua das Palmeiras 120, ap 32", items: "4 pães de queijo", status: "requested", created_at: 3.minutes.ago },
    { phone: "+5511990000002", name: "Bruno Salles", address: "Av. Central 900, portaria B", items: "1 café e 2 salgados", status: "requested", created_at: 7.minutes.ago },
    { phone: "+5511990000003", name: "Carla Nunes", address: "Praça da Sé 45", items: "6 salgados", status: "accepted", sequence: 1, created_at: 12.minutes.ago, accepted_at: 9.minutes.ago },
    { phone: "+5511990000004", name: "Diego Alves", address: "Rua do Comércio 8", items: "3 pães e 2 sucos", status: "arrived", sequence: 2, created_at: 25.minutes.ago, accepted_at: 18.minutes.ago, arrived_at: 4.minutes.ago },
    { phone: "+5511990000005", name: "Elisa Rocha", address: "Rua das Flores 210", items: "12 pães de queijo", status: "fulfilled", created_at: 70.minutes.ago, accepted_at: 64.minutes.ago, arrived_at: 52.minutes.ago },
    { phone: "+5511990000006", name: "Fábio Lima", address: "Rua Sem Saída 7", items: "1 pão", status: "declined", created_at: 40.minutes.ago },
    { phone: "+5511990000007", name: "Gabi Souza", address: "Av. Beira-Mar 1500", items: "1 café", status: "dropped", created_at: 90.minutes.ago, accepted_at: 85.minutes.ago },
    { phone: "+5511990000008", name: "Hugo Martins", address: "Rua Antiga 33", items: "2 pães", status: "voided", created_at: 110.minutes.ago }
  ]

  stops.each do |row|
    customer = Customer.find_or_create_by!(phone: row[:phone]) { |record| record.name = row[:name] }

    Stop.find_or_create_by!(customer: customer, address: row[:address]) do |stop|
      stop.items = row[:items]
      stop.status = row[:status]
      stop.sequence = row[:sequence]
      stop.created_at = row[:created_at]
      stop.accepted_at = row[:accepted_at]
      stop.arrived_at = row[:arrived_at]
    end
  end

  if Position.none?
    [
      [ -23.550520, -46.633308, 9 ],
      [ -23.552180, -46.634590, 5 ],
      [ -23.553840, -46.636120, 1 ]
    ].each do |latitude, longitude, minutes|
      Position.create!(latitude: latitude, longitude: longitude, created_at: minutes.minutes.ago)
    end
  end
end
