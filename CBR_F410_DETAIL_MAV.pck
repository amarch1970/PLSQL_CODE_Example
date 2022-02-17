create or replace package CBR_F410_DETAIL_MAV is

  -- Author  : R-Style Softlab
  -- Created : 01.10.2021 
  -- Purpose : ��� 0409410

  -- ���������� ����������� ������ 2. ��������� ������ ����������� ������� ���������. �������������� ������� ��������� �����������
  -- �������� �.�. 01.10.2021
  procedure Ch00Detail02
  ( p_dtOpen          dwh.ud.ExactDate
  , p_dtClose         dwh.ud.ExactDate
  , p_algCode         dwh.ud.Code
  , p_algLocalCode    dwh.ud.Code
  , p_aggCode         dwh.ud.Code
  , p_actionDir       dwh.ud.QUEActionDir
  , p_id_department   dwh.ud.Id
  , p_id_rpt_template dwh.ud.Id
  , p_id_document     dwh.ud.Id
  , p_id_rpt_type     dwh.ud.Id
  , p_id_unit         dwh.ud.Id
  , p_id_period       dwh.ud.Id
  );


  -- ���������� ������� ����� USD �� ���� ������ (��� ������� �����-������ � ������� ���)
  -- 2021.12.17 �������� �.�. 
  -- ��������� ������������ � ����������� ������ ���������� �� ����� 0409410 ��� ���������� ��������, �������� ������ ��������� �� ����� 0409410.
  -- ������ ��� ����������� ������� ����� USD �� �������� ����.
  -- ��� ���������� ����� USD �� �������� ���� ����������� ����������, ������� �� ��������� �������� �������� �� ����� 0409410
  -- p_dtClose - ����, �� ������� ������������ ������� ����� USD
procedure CheckUSDRate( p_dtClose         dwh.ud.ExactDate);

end CBR_F410_DETAIL_MAV;
/
create or replace package body CBR_F410_DETAIL_MAV is

-- ���������� ����������� ������ 2. ��������� ������ ����������� ������� ���������. �������������� ������� ��������� �����������
procedure Ch00Detail02
  ( p_dtOpen          dwh.ud.ExactDate
  , p_dtClose         dwh.ud.ExactDate
  , p_algCode         dwh.ud.Code
  , p_algLocalCode    dwh.ud.Code
  , p_aggCode         dwh.ud.Code
  , p_actionDir       dwh.ud.QUEActionDir
  , p_id_department   dwh.ud.Id
  , p_id_rpt_template dwh.ud.Id
  , p_id_document     dwh.ud.Id
  , p_id_rpt_type     dwh.ud.Id
  , p_id_unit         dwh.ud.Id
  , p_id_period       dwh.ud.Id
  ) as
-- �������� �.�. 01.10.2021
-- ���������� ����������� ������ 2. ��������� ������ ����������� ������� ���������. �������������� ������� ��������� �����������

   Log  dwh.TCBREventLog := dwh.TCBREventLog(p_id_document); -- ��� ������� ����
   l_id_FI_RUR number(16) := to_number(null); -- ID ���������� ����������� � ������
   l_USD_rate dwh.agg_cbr410ch02d.rate%type := to_number(Null); -- ���� USD � ������
   l_ass_CONSOLIDATED number(16) := to_number(Null); --  ID ����� ������� � ��������� ������


begin
    begin

      execute immediate 'alter session enable parallel dml';
      if (p_actiondir = uc.c_QUEActionDirDo) then -- ��������� ��������-������
        Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Detail02', '��������� ������ ����������� 2 �������.'));
        log.BeginLevel;

$if $$plsql_debug $then
    -- � ���������� ������ ������� ���������� ����������
        Log.AddLogRowA
        ( p_EventObject => '��������� ������'
        , p_MsgType => 4
        , p_Msg =>
                  '( p_dtOpen => '''          || to_char(p_dtOpen)          || '''' || chr(10) ||
                  ', p_dtClose => '''         || to_char(p_dtClose)         || '''' || chr(10) ||
                  ', p_algCode => '''         || to_char(p_algCode)         || '''' || chr(10) ||
                  ', p_algLocalCode => '''    || to_char(p_algLocalCode)    || '''' || chr(10) ||
                  ', p_actionDir => '''       || to_char(p_actionDir)       || '''' || chr(10) ||
                  ', p_id_department => '''   || to_char(p_id_department)   || '''' || chr(10) ||
                  ', p_id_rpt_template => ''' || to_char(p_id_rpt_template) || '''' || chr(10) ||
                  ', p_id_document => '''     || to_char(p_id_document)     || '''' || chr(10) ||
                  ', p_id_rpt_type => '''     || to_char(p_id_rpt_type)     || '''' || chr(10) ||
                  ', p_id_unit => '''         || to_char(p_id_unit)         || '''' || chr(10) ||
                  ', p_id_period => '''       || to_char(p_id_period)       || '''' || chr(10) ||
                  ')'
        );
$end

       -- 1 �������� �������������
        Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Detail02', '����� ������. �������� ������������� ��� �������'));
        execute immediate 'truncate table dwh.tmp_cbr410_det2_deparments';

        insert --+ append
        into dwh.tmp_cbr410_det2_deparments(id_department,
                                            code_department,
                                            name_department,
                                            depordnum,
                                            id_filial)
        with t_dep_fil as ( -- ��� ������� ������������� ������� ������
          select
          p.item as id_department,
          (select d.ip_department
            from dwh.det_department d
            left join dwh.ass_bank_department ad on ad.id_child = d.ip_department
                                                 and ad.id_bank_department_type = dwh.uc_accounting.f_DD_BANK_DEPARTMENT_TYPEE
            and p_dtClose between ad.dt_open and ad.dt_close
            where d.rank in (dwh.uc_accounting.f_DD_RankFilial, dwh.uc_accounting.f_DD_RankGO)
                            and p_dtClose between d.dt_open and d.dt_close
            connect by nocycle d.ip_department = prior ad.id_parent and prior d.rank not in (dwh.uc_accounting.f_DD_RankFilial, dwh.uc_accounting.f_DD_RankGO)
            start with (d.ip_department = p.item)
          ) as id_filial
          from table(dwh.parse.StrList(dwh.cbr_utl_doc.GetDepartmentList(p_id_document => p_id_document), ';')) p
        ),
         t_dep as ( -- �������� �������������, ��������� ������������ ����������

        select
               d.ip_department as id_department,
               d.code_department as code_department,
               d.name_department as name_department,
               decode(d.rank,dwh.uc_accounting.f_DD_RankGO,'0',substr(fda.value, instr(fda.value, '/', 1)+1)) as DepOrdNum, -- ����� �������. �� ��������� ��������� 0 (�� ���)
               t_dep_fil.id_filial as id_filial
              from dwh.det_department d
              join  t_dep_fil on t_dep_fil.id_department = d.ip_department
              left join dwh.fct_department_attr fda
                   join dwh.det_typedepattr dta on dta.ip_typeattr=fda.id_typeattr 
                                                and dta.code='REGISTRY_BANK_NUM' -- ��� ������ �������������
                                                and p_dtClose between dta.dt_open and dta.dt_close
                   on fda.id_department=t_dep_fil.id_filial 
                   and p_dtClose between fda.dt_open and fda.dt_close
              where  p_dtclose between d.dt_open and d.dt_close
        )
        select id_department,
               code_department,
               name_department,
               DepOrdNum,
               id_filial
        from t_dep;
        commit;
        dbms_stats.gather_table_stats(ownname => 'dwh', tabname => 'tmp_cbr410_det2_deparments', estimate_percent => 1, degree => 12);

        -- 2. ����� ������. ��� 1. ����� c������ ������
        -- ���������� ID ����� ��������� � ������� ������ 
        select  max(daak1.ip_acc_ass_kind) into l_ass_CONSOLIDATED
        from dwh.det_acc_ass_kind daak1 
        where  upper(daak1.acc_ass_kind_code) = 'CONSOLIDATED'  
                               and p_dtClose between daak1.dt_open and daak1.dt_close;

        Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Detail02', '����� ������. ��� 1. ����� c������ ������'));
        execute immediate 'truncate table DWH.TMP_CBR410_DET2_ID_OBJECTS';

        insert --+ append
        into dwh.TMP_CBR410_DET2_ID_OBJECTS(id_object)
        select 
             distinct ada.id_account_par
        from dwh.ass_det_account ada
        where ada.id_acc_ass_kind  = l_ass_CONSOLIDATED
              and p_dtClose between ada.dt_open and ada.dt_close;
        commit;
        dbms_stats.gather_table_stats(ownname => 'dwh', tabname => 'TMP_CBR410_DET2_ID_OBJECTS', estimate_percent => 1, degree => 12);

        Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Detail02', '����� ������. ��� 1'));

        execute immediate 'truncate table dwh.tmp_cbr410_det2_st1';

        -- 3. ����� ������. ��� 1. ����� �� ����������� �������
        insert --+ append
        into dwh.tmp_cbr410_det2_st1(id_row,
                                 row_code,
                                 acc_mask,
                                 is_security,
                                 is_resident,
                                 is_mask,
                                 id_account,
                                 account_number,
                                 account_name,
                                 id_balance,
                                 id_currency,
                                 balance_code,
                                 balance_vid,
                                 id_subject,
                                 is_detail,
                                 id_department,
                                 depcode,
                                 DepOrdNum)
            select
            acsc2.id_row, 
            acsc2.row_code, 
            acsc2.acc_mask, 
            acsc2.is_security, 
            case 
                when (length(acsc2.acc_mask) > 5 
                   or instr(acsc2.acc_mask,'_') != 0 
                   or instr(acsc2.acc_mask,'%') != 0) 
                 then Null -- ��� �� ����� - ������� ������� ���������� (�� ���������)
                else acsc2.is_resident
            end   as is_resident, 
            case 
                when (length(acsc2.acc_mask) > 5 
                   or instr(acsc2.acc_mask,'_') != 0 
                   or instr(acsc2.acc_mask,'%') != 0) 
                 then 1 -- ��� �� ����� - 
                else 0 -- ����� �� �� �����
            end as is_mask, 
            da.ip_account as id_account, 
            da.account_number, 
            da.account_name,  
            da.id_balance, 
            da.id_currency,
            db.balance_code, 
            db.balance_vid, 
            da.id_subject, 
            decode(adac.id_account_chi, null ,0,1) as is_detail,
            da.id_department, 
            dep.code_department, 
            dep.DepOrdNum
            from dwh.AT_CBR410_SETCALC_CH02 acsc2
            join dwh.det_account da on da.account_number like  acsc2.acc_mask||'%' 
                                   and p_dtClose between da.dt_open and da.dt_close 
                                   and p_dtClose between da.dt_open_acc and da.dt_close_acc
            join dwh.det_balance db on db.ip_balance = da.id_balance 
                                   and p_dtClose between db.dt_open and db.dt_close
            join dwh.tmp_cbr410_det2_deparments dep on dep.id_department = da.id_department
            left join dwh.ass_det_account adac on  adac.id_account_chi = da.ip_account 
                     and adac.id_acc_ass_kind = l_ass_CONSOLIDATED
                     and p_dtClose between adac.dt_open and adac.dt_close
            left join dwh.TMP_CBR410_DET2_ID_OBJECTS io on io.id_object = da.ip_account
            where p_dtClose between acsc2.dt_open and acsc2.dt_close and acsc2.acc_mask is not null
                  and io.id_object is null; -- ��������� �� ���������� ������� ������
        commit;
        dbms_stats.gather_table_stats(ownname => 'dwh', tabname => 'tmp_cbr410_det2_st1', estimate_percent => 1, degree => 12);
        
        
        --4. ����� ������. ��� 1. ����� ���������� ��������
        Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Detail02', '����� ������. ��� 1. ����� ���������� ��������'));
        execute immediate 'truncate table DWH.TMP_CBR410_DET2_ID_OBJECTS';

        insert --+ append
        into dwh.TMP_CBR410_DET2_ID_OBJECTS(id_object)
        select 
             distinct id_subject 
        from dwh.tmp_cbr410_det2_st1;
        commit;
        dbms_stats.gather_table_stats(ownname => 'dwh', tabname => 'TMP_CBR410_DET2_ID_OBJECTS', estimate_percent => 1, degree => 12);

        --5. ����� ������. ��� 2. ����� ��������� �������� dwh.det_subject_cat_val. ����������� �������������
        Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Detail02', '����� ������. ��� 2. ��������� ��������'));
        execute immediate 'truncate table dwh.tmp_cbr410_det2_subj_cat_val';

        -- �������� �������� ��������.
        --1 ��������  RESIDENT
        --2 ������� ������������ �����  GOVERNMENT
        --3 ������� ����� ���.����������  GOVERNMENT
        --4 ������� ���������� �����������  FIN_ORGANIZATION
        --5 ������� ������������ ��������� �����������
        --6 ������� ����� � ������ �������� �����������   CBR_COMMON_HEAD
        insert --+ append
        into dwh.tmp_cbr410_det2_subj_cat_val(id_subject,
                                          resident_code,
                                          government_code,
                                          fin_organization_code,
                                          cbr_common_head_code,
                                          cbr_not_bank_ko_code)
        select 
              id_subject, 
              resident_code, 
              government_code, 
              fin_organization_code, 
              cbr_common_head_code, 
              cbr_not_bank_ko_code
        from 
        (select --distinct
               acs.id_subject as id_subject,
               upper(dsc.subject_cat_code) as subject_cat_code,
               dscv.subject_cat_val_code as   subject_cat_val_code
        from dwh.det_subject_cat dsc
        join dwh.det_subject_cat_val dscv on dscv.id_subject_cat = dsc.ip_subject_cat 
                                             and p_dtClose between  dscv.dt_open and dscv.dt_close
        join dwh.ass_subject_cat acs on acs.id_subject_cat_val = dscv.ip_subject_cat_val 
                                             and p_dtClose between  acs.dt_open and acs.dt_close
        join dwh.tmp_cbr410_det2_id_objects ids on ids.id_object = acs.id_subject
        where Upper(dsc.subject_cat_code) in ('RESIDENT', 'GOVERNMENT', 'FIN_ORGANIZATION', 'CBR_COMMON_HEAD', 'CBR_NOT_BANK_KO')
              and p_dtClose between  dsc.dt_open and dsc.dt_close
        ) pivot (max(subject_cat_val_code) as code
                 for subject_cat_code in ('RESIDENT' as RESIDENT,
                                          'GOVERNMENT' as GOVERNMENT,
                                          'FIN_ORGANIZATION' as FIN_ORGANIZATION,
                                          'CBR_COMMON_HEAD' as CBR_COMMON_HEAD,
                                          'CBR_NOT_BANK_KO' as CBR_NOT_BANK_KO
                                          ));
        commit;
        dbms_stats.gather_table_stats(ownname => 'dwh', tabname => 'tmp_cbr410_det2_subj_cat_val', estimate_percent => 1, degree => 12);
        

        -- 5. ����� ������. ��� 2. ������������ �������� ��������. ������ ����� �� ������������� ��������
        Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Detail02', '����� ������. ��� 2.'));
        execute immediate 'truncate table dwh.tmp_cbr410_det2_st2';

        insert --+ append
        into dwh.tmp_cbr410_det2_st2(   id_row,
                                        row_code,
                                        acc_mask,
                                        is_security,
                                        is_resident,
                                        is_mask,
                                        id_account,
                                        account_number,
                                        account_name,
                                        id_balance,
                                        id_currency,
                                        balance_code,
                                        balance_vid,
                                        id_subject,
                                        is_detail,
                                        id_department,
                                        depcode,
                                        government_code,
                                        fin_organization_code,
                                        cbr_common_head_code,
                                        cbr_not_bank_ko_code,
                                        code_subject,
                                        typesubject,
                                        id_country,
                                        DepOrdNum)
        select
            st1.id_row,
            st1.row_code,
            st1.acc_mask,
            st1.is_security,
            st1.is_resident,
            st1.is_mask,
            st1.id_account,
            st1.account_number,
            st1.account_name,
            st1.id_balance,
            st1.id_currency,
            st1.balance_code,
            st1.balance_vid,
            st1.id_subject,
            st1.is_detail,
            st1.id_department,
            st1.depcode,
            st2_sd.GOVERNMENT_CODE,
            st2_sd.FIN_ORGANIZATION_CODE,
            st2_sd.CBR_COMMON_HEAD_CODE,
            st2_sd.CBR_NOT_BANK_KO_CODE,
            ds.code_subject,
            ds.typesubject,
            ds.id_country,
            st1.depordnum
        from dwh.tmp_cbr410_det2_st1 st1
        left join dwh.tmp_cbr410_det2_subj_cat_val st2_sd on st2_sd.id_subject = st1.id_subject
        left join dwh.det_subject ds on ds.id_subject = st1.id_subject
        where st2_sd.resident_code is null 
              or st1.is_resident is null 
              or is_mask = 1 
              or st2_sd.resident_code != 'REZ_NO';
        commit;
        dbms_stats.gather_table_stats(ownname => 'dwh', tabname => 'tmp_cbr410_det2_st2', estimate_percent => 1, degree => 12);

        -- 6 ����� ������. ��� 3. ����������� ���� ������ ������ (�������).
        -- ����� ������. ��� 3. ����� ���������� ������
        Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Detail02', '����� ������. ��� 3. ����� ���������� ������'));
        execute immediate 'truncate table dwh.tmp_cbr410_det2_id_objects';

        insert --+ append
        into dwh.tmp_cbr410_det2_id_objects(id_object)
        select distinct id_account from dwh.tmp_cbr410_det2_st2;
        commit;
        dbms_stats.gather_table_stats(ownname => 'dwh', tabname => 'tmp_cbr410_det2_id_objects', estimate_percent => 1, degree => 12);

        -- ����� ������. ��� 3. ����� ������ ������� �� ������
        Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Detail02', '����� ������. ��� 3. ����� ������ ������� �� ������'));
        execute immediate 'truncate table dwh.tmp_cbr410_det2_st3_valp';

        insert --+ append
        into dwh.tmp_cbr410_det2_st3_valp(id_account,
                                          dealtype,
                                          docnum,
                                          code_deal,
                                          id_deal,
                                          curr_code)
        select
           distinct
           tacc.id_object as id_account,
           first_value(fd.dealtype) over (partition by tacc.id_object order by decode(fd.dealtype,5,0,1), aad.dt_open desc) as dealtype, -- ���������� ������ �� 1 ����� �������� ����� (5 ��� ������)
           first_value(fd.docnum) over (partition by tacc.id_object order by decode(fd.dealtype,5,0,1), aad.dt_open desc) as docnum,
           first_value(fd.code) over (partition by tacc.id_object order by decode(fd.dealtype,5,0,1), aad.dt_open desc) as code_deal,
           first_value(fd.id_deal) over (partition by tacc.id_object order by decode(fd.dealtype,5,0,1), aad.dt_open desc) as id_deal,
           first_value(fdi.value) over (partition by tacc.id_object order by decode(fd.dealtype,5,0,1), aad.dt_open desc) as curr_code
        from dwh.tmp_cbr410_det2_id_objects tacc
        join dwh.ass_accountdeal aad on aad.ID_ACCOUNT = tacc.id_object 
                                     and p_dtClose between aad.DT_OPEN and aad.DT_CLOSE
        join dwh.fct_deal fd on fd.id_deal = aad.ID_DEAL
        join dwh.det_deal_typeattr ddt on ddt.code = 'CBR_PAY_CURRENCY'  -- ������� ������ �������
                                       and p_dtClose  between ddt.dt_open and ddt.dt_close
        join dwh.fct_deal_indicator fdi on fdi.id_deal_attr = ddt.ip_deal_typeattr 
                                       and fdi.id_deal = fd.id_deal and p_dtClose  between fdi.dt_open and fdi.dt_close;
        commit;
        dbms_stats.gather_table_stats(ownname => 'dwh', tabname => 'tmp_cbr410_det2_st3_valp', estimate_percent => 1, degree => 12);
        

        -- 7. ����� ������. ��� 4. �����  ������� ������ ��� ��������� � ����������� � ������������ � ����� ������� � ����� ������ ������/�������.
        Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Detail02', '����� ������. ��� 4. �����  ������� ������ � ������������ � ����� ������� � ����� ������ ������/�������'));
        execute immediate 'truncate table dwh.tmp_cbr410_det2_st3';

        insert --+ append
        into dwh.tmp_cbr410_det2_st3(id_row,
                                     row_code,
                                     acc_mask,
                                     is_security,
                                     is_resident,
                                     is_mask,
                                     id_account,
                                     account_number,
                                     account_name,
                                     id_balance,
                                     id_currency,
                                     balance_code,
                                     balance_vid,
                                     id_subject,
                                     is_detail,
                                     id_department,
                                     depcode,
                                     government_code,
                                     fin_organization_code,
                                     cbr_common_head_code,
                                     cbr_not_bank_ko_code,
                                     code_subject,
                                     typesubject,
                                     id_country,
                                     curr_code,
                                     dealtype,
                                     docnum,
                                     code_deal,
                                     id_deal,
                                     DepOrdNum)
        select
          st2.id_row,
          st2.row_code,
          st2.acc_mask,
          st2.is_security,
          st2.is_resident,
          st2.is_mask,
          st2.id_account,
          st2.account_number,
          st2.account_name,
          st2.id_balance,
          st2.id_currency,
          st2.balance_code,
          st2.balance_vid,
          st2.id_subject,
          st2.is_detail,
          st2.id_department,
          st2.depcode,
          st2.government_code,
          st2.fin_organization_code,
          st2.cbr_common_head_code,
          st2.cbr_not_bank_ko_code,
          st2.code_subject,
          st2.typesubject,
          st2.id_country,
          nvl(st3_valp.curr_code, substr(st2.account_number,6,3)) as curr_code,
          st3_valp.dealtype,
          st3_valp.docnum,
          st3_valp.code_deal,
          st3_valp.id_deal,
          st2.DepOrdNum
        from dwh.tmp_cbr410_det2_st2 st2
        left join dwh.tmp_cbr410_det2_st3_valp st3_valp on st3_valp.id_account = st2.id_account
        where st2.typesubject = 4 -- ��� ����� �������� ����� �� ���� �������
              or (nvl(st3_valp.curr_code, substr(st2.account_number,6,3)) not in ('810', '643'));
        commit;
        dbms_stats.gather_table_stats(ownname => 'dwh', tabname => 'tmp_cbr410_det2_st3', estimate_percent => 1, degree => 12);
        

        --8. ����� ������. ��� 5.	����� ������� ������ � ����������� �� ������� �� �����.
        Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Detail02', '����� ������. ��� 5.	����� ������� ������ � ����������� �� ������� �� �����.'));
        execute immediate 'truncate table dwh.tmp_cbr410_det2_st5';

        insert --+ append
        into dwh.tmp_cbr410_det2_st5(id_row,
                                     row_code,
                                     acc_mask,
                                     is_security,
                                     is_resident,
                                     is_mask,
                                     id_account,
                                     account_number,
                                     account_name,
                                     id_balance,
                                     id_currency,
                                     balance_code,
                                     balance_vid,
                                     id_subject,
                                     is_detail,
                                     id_department,
                                     depcode,
                                     government_code,
                                     fin_organization_code,
                                     cbr_common_head_code,
                                     cbr_not_bank_ko_code,
                                     code_subject,
                                     typesubject,
                                     id_country,
                                     curr_code,
                                     dealtype,
                                     docnum,
                                     code_deal,
                                     id_deal,
                                     val_rst_acc,
                                     curr_row,
                                     DepOrdNum)

        select
            st3.id_row,
            st3.row_code,
            st3.acc_mask,
            st3.is_security,
            st3.is_resident,
            st3.is_mask,
            st3.id_account,
            st3.account_number,
            st3.account_name,
            st3.id_balance,
            st3.id_currency,
            st3.balance_code,
            st3.balance_vid,
            st3.id_subject,
            st3.is_detail,
            st3.id_department,
            st3.depcode,
            st3.government_code,
            st3.fin_organization_code,
            st3.cbr_common_head_code,
            st3.cbr_not_bank_ko_code,
            st3.code_subject,
            st3.typesubject,
            st3.id_country,
            st3.curr_code,
            st3.dealtype,
            st3.docnum,
            st3.code_deal,
            st3.id_deal,
            case when (st3.row_code in ('2�10', '2�20', '2�30') and st3.balance_vid = '�')
                      or (st3.row_code in ('2�10', '2�20', '2�30') and st3.balance_vid = '�') 
                 then - round(abs(aadv.val_rst_acc),2)
                 else  round(abs(aadv.val_rst_acc),2)
             end as  val_rst_acc, -- ���� ������� ������������ � ������������ � ����� �/� ������  � �/� �����
             coalesce(at_curr.rep_cur_code, '999') as curr_row,
             st3.depordnum
        from dwh.tmp_cbr410_det2_st3 st3
        join dwh.agg_account_deal_view aadv on aadv.dt = p_dtclose -- ���� � ���������� ������� ����� ����������� �� ������������� ������ �������� �� ������������� dwh.agg_account_deal_view
                                            and aadv.layer_code in ('GL', 'DETAIL') 
                                            and aadv.id_account = st3.id_account 
                                            and aadv.id_deal = -1
        -- ���� � ���������� ������� ����� ���������� �� �������������� ������ �������� �� ������������� dwh.agg_account_deal_view 
        -- (��� ����� ���� ��� ������������ ���������� ���������� ������ �� ������ ����� (�� ���������� ���. � ������, ��� ������������)
        -- ���������� ������� ���� ��� dwh.agg_account_deal_view aadv --+ NO_INDEX, 
        -- ����� ����� �� dwh.agg_account_deal_view aadv �������� ��� �� �� ������� (�����), � �� ��������
        
        left join DWH.AT_CBR410_CUR_CH010204 at_curr on at_curr.acc_cur_code = st3.curr_code 
                                                     and p_dtClose between at_curr.dt_open and at_curr.dt_close
        where aadv.val_rst_acc is not null and aadv.val_rst_acc != 0;
        commit;
        dbms_stats.gather_table_stats(ownname => 'dwh', tabname => 'tmp_cbr410_det2_st5', estimate_percent => 1, degree => 12);
        

        --8. ���������� ����������� 2 �������. ����� ��������� ��������.
        --   ����� ��������
        Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Detail02', '���������� ����������� 2. ����� ��������� ��������. ����� ��������'));

        execute immediate 'truncate table dwh.tmp_cbr410_det2_id_objects';

        insert --+ append
        into dwh.tmp_cbr410_det2_id_objects(id_object)
        select distinct st5.id_subject from dwh.tmp_cbr410_det2_st5 st5;
        commit;
        dbms_stats.gather_table_stats(ownname => 'dwh', tabname => 'tmp_cbr410_det2_id_objects', estimate_percent => 1, degree => 12);

        --   ����� ���������
        Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Detail02', '���������� ����������� 2. ����� ��������� ��������. ����� ���������'));
        execute immediate 'truncate table dwh.tmp_cbr410_det2_st5_subj_atr';

        insert --+ append
        into dwh.tmp_cbr410_det2_st5_subj_atr(id_subject,
                                              cbr_rate_share_in_bank_val,
                                              cbr_rate_share_in_client_val)
        select  id_subject,
                cbr_rate_share_in_bank_val,
                cbr_rate_share_in_client_val
        from (
          select

             tSubj.Id_Object as id_subject,
             dta.code as code_attr,
             fsi.value as fsi_value
          from dwh.tmp_cbr410_det2_id_objects tSubj
          join dwh.det_typeattr dta on dta.code in ('CBR_RATE_SHARE_IN_BANK', 'CBR_RATE_SHARE_IN_CLIENT') 
                                    and p_dtclose between dta.dt_open and dta.dt_close
          join dwh.fct_subj_indicator fsi on fsi.id_typeattr = dta.ip_typeattr 
                                          and fsi.id_subject = tSubj.Id_Object 
                                          and p_dtclose between fsi.dt_open and fsi.dt_close
          )  pivot (max(fsi_value) as val
                   for code_attr in (
                                     'CBR_RATE_SHARE_IN_BANK' as CBR_RATE_SHARE_IN_BANK,
                                     'CBR_RATE_SHARE_IN_CLIENT' as CBR_RATE_SHARE_IN_CLIENT
                                            ));
        commit;
        dbms_stats.gather_table_stats(ownname => 'dwh', tabname => 'tmp_cbr410_det2_st5_subj_atr', estimate_percent => 1, degree => 12);
        
        --  ������ ��������� ��������
        Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Detail02', '���������� ����������� 2. ������ ��������� ��������'));
        merge --+ parallel(8)
        into dwh.tmp_cbr410_det2_st5 src
        using (select  id_subject,
                cbr_rate_share_in_bank_val,
                cbr_rate_share_in_client_val
                from dwh.tmp_cbr410_det2_st5_subj_atr) dst
        on (dst.id_subject = src.id_subject)
        when matched then update
             set src.perc_of_part_cl = to_number(dst.cbr_rate_share_in_bank_val),
                 src.perc_of_part_bank = to_number(dst.cbr_rate_share_in_client_val);
        commit;


        -- 9. ���������� ������ ���������
        Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Detail02', '���������� ������ ���������'));
        execute immediate 'truncate table dwh.tmp_cbr410_det2_ressect';

        insert --+ append
        into dwh.tmp_cbr410_det2_ressect(id_account, res_sector_code)
        select
          st5.id_account,
          min(nt_rs.res_sector_code ) keep (dense_rank first order by nt_rs.prioritet, nt_rs.id_row) as res_sector_code
        from dwh.tmp_cbr410_det2_st5 st5
        join DWH.AT_CBR410_RES_SECTOR_CH02 nt_rs on
             p_dtclose between nt_rs.dt_open and nt_rs.dt_close
             and (nt_rs.acc_mask is null or st5.account_number like nt_rs.acc_mask||'%')
             and (nt_rs.type_subject is null or nt_rs.type_subject = st5.typesubject)
             and (nt_rs.is_central_bank is null or nt_rs.is_central_bank = decode(st5.government_code,2,1,0))
             and (nt_rs.is_government is null or nt_rs.is_government = decode(st5.government_code,null,0,1))
             and (nt_rs.Fin_Organization is null or nt_rs.Fin_Organization = decode(st5.fin_organization_code,null,0,1))
             and (nt_rs.is_nko is null or nt_rs.is_nko = decode(st5.cbr_not_bank_ko_code,null,0,1))
             and (nt_rs.gen_go is null or nt_rs.gen_go = decode(st5.cbr_common_head_code,null,0,1))
             and (nt_rs.perc_of_part_cl is null or nt_rs.perc_of_part_cl = case when st5.perc_of_part_cl is null 
                                                                                     or st5.perc_of_part_cl = 0 then 0
                                                                                when st5.perc_of_part_cl < 10 then 1
                                                                                else 2 end) -- --0-���; 1 = ������ 10%; 2 - >= 10%
             and (nt_rs.perc_of_part_bank is null or nt_rs.perc_of_part_bank = case when st5.perc_of_part_bank is null 
                                                                                         or st5.perc_of_part_bank = 0 then 0
                                                                                    when st5.perc_of_part_bank < 10 then 1
                                                                                    else 2 end) -- --0-���; 1 = ������ 10%; 2 - >= 10%
        group by st5.id_account;
        commit;
        dbms_stats.gather_table_stats(ownname => 'dwh', tabname => 'tmp_cbr410_det2_ressect', estimate_percent => 1, degree => 12);
        
        --���������� ������ ���������
        Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Detail02', '���������� ������ ���������'));
        merge --+ parallel(8)
        into dwh.tmp_cbr410_det2_st5 src
        using (select  id_account, 
                       res_sector_code 
               from dwh.tmp_cbr410_det2_ressect) dst
        on (dst.id_account = src.id_account)
        when matched then update
                           set src.SECTOR_CODE = to_number(dst.res_sector_code);
        commit;

        --10. ���������� ����� ��� ���������� ����� �/�
        Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Detail02', '���������� ����� ��� ���������� ����� �/�'));
        execute immediate 'truncate table dwh.tmp_cbr410_det2_id_objects';

        insert --+ append
        into dwh.tmp_cbr410_det2_id_objects(id_object)
        select
          distinct
          st5.id_account
        from dwh.tmp_cbr410_det2_st5 st5
        join dwh.at_cbr410_excl_ch02 nt_ex on  p_dtclose between nt_ex.dt_open and nt_ex.dt_close
                                           and nt_ex.res_sector_code = nvl(st5.sector_code, 850)
                                           and ((nt_ex.acc_excl_mask is null) 
                                              or( st5.account_number like nt_ex.acc_excl_mask||'%'))
                                           and ((nt_ex.curr_excl is null) 
                                              or (st5.curr_row = nt_ex.curr_excl));
        commit;
        dbms_stats.gather_table_stats(ownname => 'dwh', tabname => 'tmp_cbr410_det2_id_objects', estimate_percent => 1, degree => 12);

        -- ��������� ���� ������/�������
        Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Detail02', '��������� ���� ������/�������'));
        merge --+ parallel(8)
        into dwh.tmp_cbr410_det2_st5 src
        using (select  
                   id_object 
               from dwh.tmp_cbr410_det2_id_objects) dst
        on (dst.id_object = src.id_account)
        when matched then update
                          set src.row_code = NULL;
        commit;

        --11. ������ ���������� ������� ����������� 2 ������� � ������� ������
        Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Detail02', '������ ���������� ������� ����������� 2 ������� � ������� ������'));

        -- ���������� ID ����������� ����������� �� ������ (��� ������� �����-������ � ������� ���)
        begin
          select dcRUR.Id_Finstr into l_id_FI_RUR
          from dwh.det_currency dcRUR
          where dcRUR.curr_code_txt = 'RUR' 
                and p_dtClose between dcRUR.dt_open and dcRUR.dt_close;
        exception
          when NO_DATA_FOUND then
              Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Detail02','������ �������. ������ ��� �������: ����������� ������ � ����� RUR',dwh.uc.c_BoolTrue));
              log.EndLevel;
              execute immediate 'alter session disable parallel dml';
              TSRPException.RaiseException( p_ExceptionCode => 'EDocumentAction', p_Param1 => '������ �������. ������ ��� �������: ����������� ������ � ����� RUR' );
        end;

        -- ���������� ���� USD (��� ������� �����-������ � ������� ���)
        begin
          select  round((dfr.finstr_rate/dfr.finstr_scale),4) into l_USD_Rate
               from dwh.det_currency dc
               join dwh.fct_finstr_rate dfr
                    join dwh.det_type_rate drr on drr.type_rate_code = 'CBRF' 
                                               and drr.ip_type_rate = dfr.id_type_finstr_rate 
                                               and p_dtClose between drr.dt_open and drr.dt_close
               on dfr.id_finstr_numerator = dc.id_finstr
                  and dfr.id_finstr_denominator = l_id_FI_RUR
                  and p_dtClose between dfr.dt_open and dfr.dt_close
               where dc.curr_code_txt = 'USD' 
                     and p_dtClose between dc.dt_open and dc.dt_close;
        exception
          when NO_DATA_FOUND then
              Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Detail02','������ �������. ������ ��� ������� ����������� 2 �������: ����������� ���� �� ������ USD �� ���� '|| to_char(p_dtClose, 'dd.mm.yyyy')||'; ',dwh.uc.c_BoolTrue));
              log.EndLevel;
              execute immediate 'alter session disable parallel dml';
              TSRPException.RaiseException( p_ExceptionCode => 'EDocumentAction', p_Param1 => '������ �������. ������ ��� ������� ����������� 2 �������: ����������� ���� �� ������ USD �� ���� '|| to_char(p_dtClose, 'dd.mm.yyyy') );
        end;
        
        -- ���������� ����������� �������� ����������� 2 ������� � ���������� � �������
        insert --+ append
        into dwh.agg_cbr410ch02d(
                                 id_document,
                                 id_rpt_type,
                                 dt,
                                 subject_code,
                                 id_subject,
                                 subject_name,
                                 country_code,
                                 sector_code,
                                 curr_row,
                                 code_balance,
                                 curr_code_acc,
                                 account_number,
                                 account_name,
                                 id_account,
                                 rate,
                                 sum,
                                 sum_usd,
                                 row_code,
                                 regnum_department,
                                 code_department,
                                 id_department,
                                 type_subject,
                                 is_central_bank,
                                 is_government,
                                 fin_organization,
                                 is_nko,
                                 perc_of_part_cl,
                                 perc_of_part_bank,
                                 is_general_head,
                                 security_num,
                                 id_security,
                                 deal_num,
                                 id_deal,
                                 curr_rep)
        with t_curr as ( -- ������ ����� �� ������
             select --+ MATERIALIZE
                    distinct st5.id_currency
             from dwh.tmp_cbr410_det2_st5 st5
          ), t_rate as ( -- ����� ����� �����
            select --+ MATERIALIZE
               t_curr.id_currency,
               dc.curr_code_txt,
               decode(dc.curr_code_txt, 'USD', 1, 'RUR', l_USD_Rate, round(l_USD_Rate /round((dfr.finstr_rate/dfr.finstr_scale),4),4)) as CrossCurs
            from t_curr
            join dwh.det_currency dc on dc.ip_currency = t_curr.id_currency 
                                           and p_dtClose between dc.dt_open and dc.dt_close
            left join dwh.fct_finstr_rate dfr
                join dwh.det_type_rate drr on drr.type_rate_code = 'CBRF' 
                                           and drr.ip_type_rate = dfr.id_type_finstr_rate 
                                           and p_dtClose between drr.dt_open and drr.dt_close
            on dfr.id_finstr_numerator = dc.id_finstr
                and dfr.id_finstr_denominator = l_id_FI_RUR
                and p_dtClose between dfr.dt_open and dfr.dt_close
          )
        select
           p_id_document,
           p_id_rpt_type,
           p_dtClose,
           st5.code_subject as subject_code,
           st5.id_subject as id_subject,
           coalesce(db.name_s, djp.juridic_person_name, de.name, dpp.person_name) as subject_name,
           decode(coalesce(dcy.ip_country, -1), -1, '-1', dcy.country_code_num) as country_code,
           coalesce(st5.sector_code, 850) as  sector_code, --  4 ��� �������  �������� (���������)
           st5.curr_row as curr_row, -- 5 ������ ������ (�������)
           substr(st5.account_number,1,5) as code_balance, -- 6. ��
           substr(st5.account_number,6,3) as curr_code_acc, --7. �������� ��� ������ �����
           st5.account_number as account_number, -- 8.����� �������� �����
           st5.account_name as account_name, --9. ������������  �������� �����
           st5.id_account as id_account,
           t_rate.CrossCurs as rate, -- 10.���� / �����-����
           round(st5.val_rst_acc,2) as val_rst_acc, --11. �����, ������ �����
           round(round(st5.val_rst_acc,2)/ t_rate.CrossCurs,2) as sum_usd, -- 12.�����, ����.���
           st5.row_code as row_code, -- 13.��� ������ (�������)    ���������� ������ ���������� - ����������
           st5.DepOrdNum as regnum_department, -- 14. ���������� ����� ������� (��������� �����) �����
           st5.depcode as code_department, --15.��� ������������ �������������
           st5.id_department as id_department,
           decode(st5.typesubject,1, '��',2, '��', 3,'��', 4, '����', '�� ���������') as type_subject, -- 16. ��� �������
           decode(st5.government_code,2,1, NULL) as is_central_bank, --17 ������� ������������ �����
           decode(st5.government_code,NULL,to_number(NULL),1) as is_government, --18 ������� ����� ���.����������
           decode(st5.FIN_ORGANIZATION_CODE,NULL,to_number(NULL),1) as fin_organization,-- 19. ������� ���������� �����������
           decode(st5.CBR_NOT_BANK_KO_CODE,NULL,to_number(NULL),1) as is_nko, -- 20. ������� ������������ ��������� �����������
           st5.perc_of_part_cl /*to_number(subj_attr.CBR_RATE_SHARE_IN_BANK_VAL)*/ as perc_of_part_cl, --21 ������� ������� �������
           st5.perc_of_part_bank /*to_number(subj_attr.CBR_RATE_SHARE_IN_CLIENT_VAL)*/ as perc_of_part_bank, --22.������� ������� �����
           decode(st5.CBR_COMMON_HEAD_CODE,NULL,to_number(NULL),1) as is_general_head, --23.������� ����� � ������ �������� �����������
           to_char(null) as security_num, -- 24. ����� ������ ������
           to_number(null) as id_security,
           st5.docnum as deal_num, --25. ����� ������
           st5.id_deal as id_deal,
           st5.curr_code as curr_rep -- 26. ������, ������������ ��  ����� ������ ������

        from dwh.tmp_cbr410_det2_st5 st5
        left join dwh.det_phyz_person dpp on dpp.id_subject = st5.id_subject 
                                          and p_dtClose between dpp.dt_open and dpp.dt_close
        left join dwh.det_entrepreneur de on de.id_phyz_person = dpp.id_phyz_person
                                          and p_dtClose between de.dt_open and de.dt_close                                  
        left join dwh.det_juridic_person djp on djp.id_subject = st5.id_subject 
                                          and p_dtClose between djp.dt_open and djp.dt_close
        left join dwh.det_Bank db on db.id_subject = st5.id_subject 
                                          and p_dtClose between db.dt_open and db.dt_close
        left join dwh.det_country dcy on dcy.ip_country = st5.id_country 
                                      and p_dtClose between dcy.dt_open and dcy.dt_close
        left join t_rate on t_rate.id_currency = st5.id_currency;
        commit;



        Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Detail02', '�������� ��������� ������.'));

        execute immediate 'truncate table dwh.tmp_cbr410_det2_deparments';
        execute immediate 'truncate table dwh.tmp_cbr410_det2_st1';
        execute immediate 'truncate table dwh.tmp_cbr410_det2_subj_cat_val';
        execute immediate 'truncate table dwh.tmp_cbr410_det2_st2';
        execute immediate 'truncate table dwh.tmp_cbr410_det2_id_objects';
        execute immediate 'truncate table dwh.tmp_cbr410_det2_st3_valp';
        execute immediate 'truncate table dwh.tmp_cbr410_det2_st3';
        execute immediate 'truncate table dwh.tmp_cbr410_det2_st5';
        execute immediate 'truncate table dwh.tmp_cbr410_det2_st5_subj_atr';
        execute immediate 'truncate table dwh.tmp_cbr410_det2_ressect';

        Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Detail02', '���������� ������� ����������� 2 �������.'));
        log.EndLevel;
        commit;


      end if;

      if (p_actiondir = uc.c_QUEActionDirUndo) then
         --��������� ����� ������� ����������� 2 �������
        Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Detail02', '��������� ����� ������� ����������� 2 �������.'));
        log.BeginLevel;
        -- ��������� ��������-�����
        delete dwh.agg_cbr410ch02d t
         where t.id_document = p_id_document;
        commit;
        Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Detail02', '���������� ������ ������� ����������� 2 �������.'));
        log.EndLevel;
      end if;

      execute immediate 'alter session disable parallel dml';
    exception
      when OTHERS then
        Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Detail02','������ ��� �������: '||sqlerrm,dwh.uc.c_BoolTrue));
        log.EndLevel;
        TSRPException.RaiseException( p_ExceptionCode => 'EDocumentAction', p_Param1 => '��� ������: '||p_id_rpt_type );
        execute immediate 'alter session disable parallel dml';
    end;


   commit;

end Ch00Detail02;


        -- ���������� ������� ����� USD �� ���� ������ (��� ������� �����-������ � ������� ���)
procedure CheckUSDRate( p_dtClose  dwh.ud.ExactDate)
        -- 2021.12.17 �������� �.�. 
        -- ��������� ������������ � ����������� ������ ���������� �� ����� 0409410 ��� ���������� ��������, �������� ������ ��������� �� ����� 0409410.
        -- ������ ��� ����������� ������� ����� USD �� �������� ����.
        -- ��� ���������� ����� USD �� �������� ���� ����������� ����������, ������� �� ��������� �������� �������� �� ����� 0409410
        -- p_dtClose - ����, �� ������� ������������ ������� ����� USD
is 
   l_id_FI_RUR Number(16) := to_number(NULL);
   l_USD_Rate Number(16) := to_number(NULL);
begin
  begin
    select dcRUR.Id_Finstr into l_id_FI_RUR
    from dwh.det_currency dcRUR
    where dcRUR.curr_code_txt = 'RUR' 
          and p_dtClose between dcRUR.dt_open and dcRUR.dt_close;
  exception
  when NO_DATA_FOUND then
     dwh.tsrpexception.RaiseException(p_ExceptionCode => 'ECUSTOMEXCEPTION',
                                      p_Param1        => '�������� ��������� ����������! ����������� ���������� ���������� � ����� RUR');
  end;

  select  round((dfr.finstr_rate/dfr.finstr_scale),4) into l_USD_Rate
       from dwh.det_currency dc
       join dwh.fct_finstr_rate dfr
            join dwh.det_type_rate drr on drr.type_rate_code = 'CBRF' 
                                       and drr.ip_type_rate = dfr.id_type_finstr_rate 
                                       and p_dtClose between drr.dt_open and drr.dt_close
       on dfr.id_finstr_numerator = dc.id_finstr
          and dfr.id_finstr_denominator = l_id_FI_RUR
          and p_dtClose between dfr.dt_open and dfr.dt_close
       where dc.curr_code_txt = 'USD' 
             and p_dtClose between dc.dt_open and dc.dt_close;
exception
  when NO_DATA_FOUND then
     dwh.tsrpexception.RaiseException(p_ExceptionCode => 'ECUSTOMEXCEPTION',
                                      p_Param1        => '�������� ��������� ����������! ����������� ���� �� ������ USD �� ���� '|| to_char(p_dtClose, 'dd.mm.yyyy'));
end CheckUSDRate;


end CBR_F410_DETAIL_MAV;
/
