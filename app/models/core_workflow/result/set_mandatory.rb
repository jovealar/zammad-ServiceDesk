# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Result::SetMandatory < CoreWorkflow::Result::Backend
  def run
    @result_object.result[:mandatory][field] = true
    true
  end
end
