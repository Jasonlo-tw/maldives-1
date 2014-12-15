json.array!(@purchasing_order_lineitems) do |purchasing_order_lineitem|
  json.extract! purchasing_order_lineitem, :id, :purchasing_order_id, :sequence_no, :material_id, :quantity, :purchased_unit_price, :amount, :tax, :purchasing_requisition_no, :purchasing_requsition_seq_no, :purchasing_purpose, :purchasing_requisition_date, :goods_need_date, :shipping_location, :acceptance_certification_no, :close_case, :acc_type, :cost_department
  json.url purchasing_order_lineitem_url(purchasing_order_lineitem, format: :json)
end
