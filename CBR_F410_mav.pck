create or replace package CBR_F410_MAV is

  -- Author  : R-Style Softlab
  -- Created : 01.10.2021 07:50:00
  -- Purpose : ��� 0409410

  -- ��� ������� ����� - � ������ ���������
  -- �������� �.�. 01.10.2021
  -- ������ ����� � ������ ���������
  procedure Ch00Exact
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

  -- �������� �.�. 01.10.2021
  -- ������ ����� � ����������� ���������
  procedure Ch00Round
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

  -- ��� ������� ����� - � �������������� ��������� (������ �����)
  -- �������� �.�. 01.10.2021
  -- ������ ����� � ������� �����
    procedure Ch00Adjust
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

  -- �������� ��������� �����
-- �������� �.�. 01.10.2021
-- ��������� ������������� ������ ������ � ������������ � ����������� �����������
-- � ������������ �  N 4927-�  � ������ ���� �������� ��������� �����, �������� � �����.
-- ��������� �������� ������ ������ �������� � �����, ������ �� �������� � ����� �� ������� ������ �� ����������
  procedure ReCount_Row_Num
  (
    p_dtClose         dwh.ud.ExactDate
  , p_id_rpt_template dwh.ud.Id
  , p_id_document     dwh.ud.Id
  , p_id_rpt_type     dwh.ud.Id
  , p_id_chapter      dwh.ud.Id default null -- ����� ������� ��� ���������, ���� �� ����� ��� 0, �� �� ���� ��������
  );

-- �������� �.�. 01.10.2021
-- ��������� ������������� �������� ������
-- ������ ��������� ��������, ���� � ������� � ��� ���� �������� ������.
  procedure ReCount_TotalRows
  (
    p_dtClose         dwh.ud.ExactDate
  , p_id_rpt_template dwh.ud.Id
  , p_id_document     dwh.ud.Id
  , p_id_rpt_type     dwh.ud.Id
  , p_id_chapter      dwh.ud.Id default null -- ����� ������� ��� ���������, ���� �� ����� ��� 0, �� �� ���� ��������. �������� ������ ���� ������ �� 1 �������
  );



end CBR_F410_MAV;
/
create or replace package body CBR_F410_MAV is

-- ��������� ������������� ������ ������ � ����������� � ������������ �����������
  procedure ReCount_Row_Num
  (
    p_dtClose         dwh.ud.ExactDate -- ���� ������
  , p_id_rpt_template dwh.ud.Id -- ID ������f ������
  , p_id_document     dwh.ud.Id -- ID ��������� ������
  , p_id_rpt_type     dwh.ud.Id -- ID ���� ������
  , p_id_chapter      dwh.ud.Id default null -- ����� ������� ��� ���������, ���� �� ����� ��� 0, �� �� ���� ��������
  ) as
-- �������� �.�. 01.10.2021
-- ��������� ������������� ������ ������ � ������������ � ����������� �����������
-- � ������������ �  N 4927-�  � ������ ���� �������� ��������� �����, �������� � �����.
-- ��������� �������� ������ ������ �������� � �����, ������ �� �������� � ����� �� ������� ������ �� ����������

  begin
    -- 1 �������� ��������� �����
    update DWH.AGG_CBR410CH# agg
           set agg.row_num = NULL
    where agg.id_document = p_id_document
          and agg.id_rpt_type = p_id_rpt_type
          and (nvl(p_id_chapter,0) = 0 
               or (agg.chapter_num = p_id_chapter));

    -- 2 ���������� ������������� �����
    merge into DWH.AGG_CBR410CH# src
    using (
    select drr.row_number,
          agg.rowid as id_row,
          agg.id_document, 
          agg.id_rpt_type, 
          agg.chapter_num, 
          agg.row_code, 
          agg.sector_code, 
          agg.country_code, 
          agg.cur_code, 
          agg.val_rst
          , row_number() over (partition by agg.chapter_num order by drr.row_number, agg.row_code, agg.sector_code, agg.country_code, agg.cur_code) as row_num
          from DWH.AGG_CBR410CH# agg
          join dwh.det_rpt_template drt on drt.id_rpt_template = p_id_rpt_template
          join dwh.det_rpt_tmpl_chapter drtc on drtc.id_rpt_template = drt.ip_rpt_template
          join dwh.det_rpt_rows drr on drr.id_tmpl_chapter = drtc.ip_tmpl_chapter 
               and drr.row_code = agg.row_code
          where agg.id_document = p_id_document
                and agg.id_rpt_type = p_id_rpt_type
                and (nvl(p_id_chapter,0) = 0 or (agg.chapter_num = p_id_chapter))
                and drr.block_number = agg.chapter_num 
                and p_dtClose between drr.dt_open and drr.dt_close
                and p_dtClose between drtc.dt_open and drtc.dt_close
                and  p_dtClose between drt.dt_open and drt.dt_close
                and ( (agg.sector_code is not null
                       and agg.val_rst is not null and agg.val_rst != 0)
                    or ((agg.sector_code is null 
                         and agg.country_code is null 
                         and agg.cur_code is null)
                       and not exists (select 1 from DWH.AGG_CBR410CH# aggd
                                       where     aggd.id_document = agg.id_document
                                             and aggd.id_rpt_type = agg.id_rpt_type
                                             and aggd.chapter_num = agg.chapter_num
                                             and aggd.row_code = agg.row_code
                                             and aggd.sector_code is not null
                                             and agg.val_rst is not null 
                                             and aggd.val_rst != 0)))
    ) dst on (src.id_document = dst.id_document
              and src.id_rpt_type = dst.id_rpt_type
              and src.rowid = dst.id_row
              )
    when matched then update
         set src.row_num = dst.row_num;

    commit;

  end ReCount_Row_Num;

-- ��������� ������������� �������� ������
  procedure ReCount_TotalRows
  (
    p_dtClose         dwh.ud.ExactDate -- ���� ������
  , p_id_rpt_template dwh.ud.Id -- ID �������
  , p_id_document     dwh.ud.Id -- id ��������� ������
  , p_id_rpt_type     dwh.ud.Id -- id ���� ������
  , p_id_chapter      dwh.ud.Id default null -- ����� ������� ��� ���������, ���� �� ����� ��� 0, �� �� ���� ��������. �������� ������ ���� ������ �� 1 �������
  ) as
-- �������� �.�. 01.10.2021
-- ��������� ������������� �������� ������
-- ������ ��������� ��������, ���� � ������� � ��� ���� �������� ������.

  begin
    merge into DWH.AGG_CBR410CH# src
    using (
        with total_rows as -- ���������� �� ������� ��������� ������
         (select
          distinct level as lv, -- ������� ��������
                   CONNECT_BY_ROOT pdrr.row_code as root_code, --��� �������� ������
                   CONNECT_BY_ROOT pdrr.ip_row as id_row, -- ID �������� ������
                   cdrr.block_number as chapter_num, -- ����� ������� ������
                   cdrr.ip_row      as id_child, -- ID �������� ������
                   cdrr.row_code    as child_code -- ��� �������� ������
            from dwh.det_rpt_tmpl_chapter drtc
            join dwh.det_rpt_rows pdrr
              on pdrr.id_tmpl_chapter = drtc.ip_tmpl_chapter
             and p_dtClose between  pdrr.dt_open and pdrr.dt_close
            join dwh.ass_det_rpt_rows adrr
              on adrr.id_parent = pdrr.ip_row
              and p_dtClose between adrr.dt_open and adrr.dt_close
            join dwh.det_rpt_rows cdrr
              on cdrr.id_tmpl_chapter = drtc.ip_tmpl_chapter
             and p_dtClose between cdrr.dt_open and cdrr.dt_close
             and cdrr.ip_row = adrr.id_child
           where drtc.id_rpt_template = p_id_rpt_template
                 and p_dtClose between drtc.dt_open and drtc.dt_close
          connect by adrr.id_parent = prior adrr.id_child
        )
          select
                  tr.root_code as root_code,
                  agg1.sector_code as sector_code,
                  agg1.country_code as country_code,
                  agg1.cur_code as cur_code,
                  sum(nvl(agg1.val_rst,0)) as val_rst
          from total_rows tr
          left join DWH.AGG_CBR410CH# agg1 on agg1.id_document = p_id_document
               and agg1.id_rpt_type = p_id_rpt_type
               and agg1.chapter_num = tr.chapter_num
          and agg1.row_code = tr.child_code
          group by tr.root_code, 
                   agg1.sector_code, 
                   agg1.country_code, 
                   agg1.cur_code
      ) dst
      on (src.id_document = p_id_document
          and src.id_rpt_type = p_id_rpt_type
          and dst.root_code = src.row_code
          and (nvl(src.sector_code, -1) = nvl(dst.sector_code,-1))
          and (nvl(src.country_code, '-1') = nvl(dst.country_code, '-1'))
          and (nvl(src.cur_code, '-1') = nvl(dst.cur_code, '-1'))
          )
      when matched then update
                        set src.val_rst =  nvl(dst.val_rst,0)
      when not matched then insert (id_document, id_rpt_type, dt, chapter_num, row_num, row_code, sector_code, country_code, cur_code, val_rst)
                            values(p_id_document, p_id_rpt_type, p_dtClose, 1, null, dst.root_code, dst.sector_code, dst.country_code, dst.cur_code, dst.val_rst);
      commit;
  end ReCount_TotalRows;


  -- ��� ������� ����� - � ������ ���������
  procedure Ch00Exact
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
  -- ������ ����� � ������ ���������
  -- ����������� ���������  ������ ���������. ������ ���������� ���.
  
    Log               dwh.TCBREventLog := dwh.TCBREventLog(p_id_document); -- ��� �����
    l_id_rpt_type_exact             number; -- ID ���� ����� � ������ ���������
  begin

    -- ���������� �� ����� � ������ ���������. �������� ������������ ����������� (�������������� ����������).
    select ip_rpt_type
      into l_id_rpt_type_exact
      from dwh.det_rpt_type drt
     where rpt_type_code = 'EXACT' 
           and p_dtClose between drt.dt_open and drt.dt_close;


    -- ��������� �������� ������ �� "����������� ��������"
    begin
      if (p_actiondir = uc.c_QUEActionDirDo) then -- ��������� ��������-������
        Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Exact', '��������� ������ ��������.'));
        log.BeginLevel;

$if $$plsql_debug $then
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

       -- ��������� ������� ������ ������/�������
       Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Exact', '��������� ������� ������� ����� ������/�������'));

        execute immediate 'truncate table dwh.tmp_cbr410rowcode';
        insert into dwh.tmp_cbr410rowcode(chapter_num, row_code)
        select  drr.block_number, drr.row_code
        from dwh.det_rpt_template drt
        join dwh.det_rpt_tmpl_chapter drtc on drtc.id_rpt_template = drt.ip_rpt_template 
             and p_dtClose between drtc.dt_open and drtc.dt_close
        join dwh.det_rpt_rows drr on drr.id_tmpl_chapter = drtc.ip_tmpl_chapter 
             and p_dtClose between drr.dt_open and drr.dt_close
        where drt.ip_rpt_template = p_id_rpt_template
            and p_dtClose between drt.dt_open and drt.dt_close;
        commit;
------------------------------------------ 1 ������ ----------------------------------------------------------------


       -- ������� 1 ������ �� �����������
       -- ������� ��������� ������� ������
       Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Exact', '��������� ������ ������ �� ����������� 1 �������.'));
       execute immediate 'truncate table dwh.tmp_cbr410Ch00Exact';
       Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Exact', '��������� ������� ����������� ������� 1'));
        insert into dwh.tmp_cbr410Ch00Exact(chapter_num, 
                                            row_num, 
                                            row_code, 
                                            sector_code, 
                                            country_code, 
                                            cur_code, 
                                            val_rst)
        select  -- parallel(8)
        1 as chapter_num,
        null as row_num,
        dt1.row_code as row_code_2_14,
        dt1.sector_code_410 as sector_code_410_3_17,
        dt1.nonres_country as nonres_country_4_5,
        dt1.curr_code_410 as curr_code_410_5_18,
        sum(dt1.rst_usd) as rst_usd_6_13
        from dwh.agg_cbr410ch01d dt1
        join dwh.tmp_cbr410rowcode trc on trc.chapter_num = 1 
             and trc.row_code = dt1.row_code
        where dt1.id_document = p_id_document 
              and dt1.id_rpt_type = l_id_rpt_type_exact 
              and dt1.row_code is not null
              and dt1.rst_usd is not null 
              and dt1.rst_usd != 0
        group by dt1.row_code, 
                 sector_code_410, 
                 nonres_country, 
                 curr_code_410;
        commit;

       Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Exact', '��������� ���������� ������� ����������� ������� 1'));


       Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Exact', '���������� ������ ������� 1 � ������� ������ '));
       Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Exact', '���������� ����� ������ �\� ������� 1 � ������� ������ '));

      -- ���������� ������ 1 ������� �� �������
      insert into dwh.agg_cbr410ch#(id_document, 
                                    id_rpt_type, 
                                    dt, 
                                    chapter_num, 
                                    row_num, 
                                    row_code, 
                                    sector_code, 
                                    country_code, 
                                    cur_code, 
                                    val_rst)
      select
             p_id_document as id_document,
             l_id_rpt_type_exact as id_rpt_type,
             p_dtClose as dt,
             drr.block_number as chapter_num,
             null as row_num,
             drr.row_code,
             null as  sector_code,
             null as  country_code,
             null as  cur_code,
             0 as val_rst
      from dwh.det_rpt_template drt
      join dwh.det_rpt_tmpl_chapter drtc on drtc.id_rpt_template = drt.ip_rpt_template 
           and p_dtClose between drtc.dt_open and drtc.dt_close
      join dwh.det_rpt_rows drr on drr.id_tmpl_chapter = drtc.ip_tmpl_chapter 
           and p_dtClose between drr.dt_open and drr.dt_close
      where drt.id_rpt_template = p_id_rpt_template
            and drr.block_number = 1
            and  p_dtClose between drt.dt_open and drt.dt_close;
      commit;

       Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Exact', '���������� ��������� ������ �\� ������� 1 � ������� ������ '));

       -- ���������� ��������� ������ 1 ������� �� �����������
      insert into dwh.agg_cbr410ch#(id_document, 
                                    id_rpt_type, 
                                    dt, 
                                    chapter_num, 
                                    row_num, 
                                    row_code, 
                                    sector_code, 
                                    country_code, 
                                    cur_code, 
                                    val_rst)
      select
             p_id_document as id_document,
             l_id_rpt_type_exact as id_rpt_type,
             p_dtClose as dt,
             drr.block_number as chapter_num,
             null as row_num,
             drr.row_code,
             tce.sector_code,
             tce.country_code,
             tce.cur_code,
             nvl(tce.val_rst,0)
      from dwh.det_rpt_template drt
      join dwh.det_rpt_tmpl_chapter drtc on drtc.id_rpt_template = drt.ip_rpt_template
      join dwh.det_rpt_rows drr on drr.id_tmpl_chapter = drtc.ip_tmpl_chapter  and  p_dtClose between drtc.dt_open and drtc.dt_close
      join dwh.tmp_cbr410ch00exact tce on tce.row_code = drr.row_code and  p_dtClose between drt.dt_open and drt.dt_close
      where drt.id_rpt_template = p_id_rpt_template
            and drr.block_number = 1 and p_dtClose between drr.dt_open and drr.dt_close
            and nvl(tce.val_rst,0) != 0; -- �������� �� ��� �� 14.12.2021
      commit;

      Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Exact', '��������� ���������� ������ ������� 1 � ������� ������'));



------------------------------------------ 2 ������ ----------------------------------------------------------------
       -- ������� 2 ������ �� �����������
       -- ������� ��������� ������� ������
       Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Exact', '��������� ������ ������ �� ����������� 2 �������.'));
       Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Exact', '������� ��������� ������� dwh.tmp_cbr410Ch00Exact'));
       execute immediate 'truncate table dwh.tmp_cbr410Ch00Exact';

       Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Exact', '��������� ������� ����������� ������� 2'));
        insert into dwh.tmp_cbr410Ch00Exact(chapter_num, 
                                            row_num, 
                                            row_code, 
                                            sector_code, 
                                            country_code, 
                                            cur_code, 
                                            val_rst)
        select  
          2 as chapter_num,
          null as row_num,
          dt2.row_code as row_code,
          dt2.sector_code as sector_code,
          null as country_code,
          dt2.curr_row as curr_code,
          sum(dt2.sum_usd) as rst_usd
        from DWH.AGG_CBR410CH02D dt2
        join dwh.tmp_cbr410rowcode trc on trc.chapter_num = 2 and trc.row_code = dt2.row_code
        where dt2.id_document = p_id_document
              and dt2.id_rpt_type = l_id_rpt_type_exact
              and dt2.row_code is not null
        group by dt2.row_code, 
                 dt2.sector_code, 
                 dt2.curr_row ;

       Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Exact', '��������� ���������� ������� ����������� ������� 2'));

       Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Exact', '���������� ������ ������� 2 � ������� ������ '));

      insert into dwh.agg_cbr410ch#(id_document, 
                                    id_rpt_type, 
                                    dt, 
                                    chapter_num, 
                                    row_num, 
                                    row_code, 
                                    sector_code, 
                                    country_code, 
                                    cur_code, 
                                    val_rst)
      select
             p_id_document as id_document,
             l_id_rpt_type_exact as id_rpt_type,
             p_dtClose as dt,
             drr.block_number as chapter_num,
             NULL as row_num,
             drr.row_code,
             tce.sector_code,
             tce.country_code,
             tce.cur_code,
             nvl(tce.val_rst,0)
      from dwh.det_rpt_template drt
      join dwh.det_rpt_tmpl_chapter drtc on drtc.id_rpt_template = drt.ip_rpt_template 
           and p_dtClose between drtc.dt_open and drtc.dt_close
      join dwh.det_rpt_rows drr on drr.id_tmpl_chapter = drtc.ip_tmpl_chapter 
           and p_dtClose between drr.dt_open and drr.dt_close
      left join dwh.tmp_cbr410ch00exact tce on tce.row_code = drr.row_code
                and nvl(tce.val_rst,0) != 0-- �������� �� ��� �� 14.12.2021
      where drt.id_rpt_template = p_id_rpt_template
            and drr.block_number = 2
            and p_dtClose between drt.dt_open and drt.dt_close
      order by drr.row_number;

-------��������  �������� ������ � ������������� �����
       Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Exact', '������� �������� ������'));

       ReCount_TotalRows(p_dtClose => p_dtClose, p_id_rpt_template => p_id_rpt_template, p_id_document=> p_id_document, p_id_rpt_type => l_id_rpt_type_exact, p_id_chapter => 0);
       Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Exact', '��������� ������� �������� ������'));

       Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Exact', '������������� ����� �������'));

       ReCount_Row_Num(p_dtClose => p_dtClose, p_id_rpt_template => p_id_rpt_template, p_id_document=> p_id_document, p_id_rpt_type => l_id_rpt_type_exact, p_id_chapter => 0);
       Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Exact', '��������� ���������� ������ ������� 2 � ������� ������'));

       commit;


        Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Exact', '���������� ������� ��������.'));
        log.EndLevel;

      end if;

      if (p_actiondir = uc.c_QUEActionDirUndo) then
        Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Exact', '��������� ����� ������� ��������.'));
        log.BeginLevel;
        -- ��������� ��������-�����
        delete dwh.agg_cbr410ch# t
         where t.id_document = p_id_document
           and t.id_rpt_type = l_id_rpt_type_exact;
        commit;
        Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Exact', '���������� ������ ������� ��������.'));
        log.EndLevel;
      end if;
    exception
      when OTHERS then
        Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Exact','������ ��� �������: '||sqlerrm,dwh.uc.c_BoolTrue));
        log.EndLevel;

        TSRPException.RaiseException( p_ExceptionCode => 'EDocumentAction', p_Param1 => '��� ������: '||p_id_rpt_type );
    end;
  end Ch00Exact;

  -- ��� ������� ����� - � ����������� ���������
  procedure Ch00Round
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
  -- ������ ����� � ����������� ���������
  -- ����������� ���������  ������ ���������. ������ ���������� ���.
  
  Log               dwh.TCBREventLog := dwh.TCBREventLog(p_id_document); -- ���
    l_id_rpt_type_exact             number; -- ID ���� ������ � ������ ���������
    l_id_rpt_type_round             number; --  ID ���� ������ � ������������ ��������� 
  begin
    -- ��������� �������� ������ �� "����������� ��������"
    begin
    
      -- ���������� �� ����� � ������ ���������. �������� ������������ ����������� (�������������� ����������).
      select id_rpt_type
          into l_id_rpt_type_exact
          from dwh.det_rpt_type drt
         where rpt_type_code = 'EXACT' 
               and p_dtClose between drt.dt_open and drt.dt_close;

      -- ���������� �� ����� � ���������� ���������. �������� ������������ ����������� (�������������� ����������).
      select id_rpt_type
        into l_id_rpt_type_round
        from dwh.det_rpt_type drt
        where rpt_type_code = 'ROUND' 
              and p_dtClose between drt.dt_open and drt.dt_close;

      if (p_actiondir = uc.c_QUEActionDirDo) then -- ��������� ��������-������
        Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Round', '��������� ������ ��������.'));
        log.BeginLevel;

        $if $$plsql_debug $then
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


       Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Round', '���������� ��������� ������� � ����������� ��������� � ������� ������ '));
       insert into dwh.agg_cbr410ch#(id_document, 
                                     id_rpt_type, 
                                     dt, 
                                     chapter_num, 
                                     row_num, 
                                     row_code, 
                                     sector_code, 
                                     country_code, 
                                     cur_code, 
                                     val_rst)
        select  -- parallel(8)
          p_id_document as id_document,
          l_id_rpt_type_round as id_rpt_type,
          p_dtClose as dt,
          agg.chapter_num as chapter_num,
          agg.row_num as row_num,
          agg.row_code as row_code4,
          agg.sector_code as sector_code,
          agg.country_code as country_code,
          agg.cur_code as cur_code,
          round(agg.val_rst/1000,3) as val_rst
        from DWH.Agg_Cbr410ch# agg
        where agg.id_document = p_id_document 
              and agg.id_rpt_type = l_id_rpt_type_exact;

-------��������  �������� ������ � ������������� �����
       Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Round', '������������� �������� ������'));

       ReCount_TotalRows(p_dtClose => p_dtClose, p_id_rpt_template => p_id_rpt_template, p_id_document=> p_id_document, p_id_rpt_type => l_id_rpt_type_round, p_id_chapter => 0);
       Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Round', '��������� ������� �������� ������'));

       Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Round', '������������� ����� ������� � ����������� ���������'));

       ReCount_Row_Num(p_dtClose => p_dtClose, p_id_rpt_template => p_id_rpt_template, p_id_document=> p_id_document, p_id_rpt_type => l_id_rpt_type_round, p_id_chapter => 0);
       Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Round', '��������� ���������� ��������� ������� � ����������� ��������� � ������� ������'));

        commit;
        Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Round', '���������� ������� ��������.'));
        log.EndLevel;

      end if;

      if (p_actiondir = uc.c_QUEActionDirUndo) then
        Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Round', '��������� ����� ������� ��������.'));
        log.BeginLevel;
        -- ��������� ��������-�����
        delete dwh.agg_cbr410ch# t
         where t.id_document = p_id_document
           and t.id_rpt_type = l_id_rpt_type_round;
        commit;
        Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Round', '���������� ������ ������� ��������.'));
        log.EndLevel;
      end if;
    exception
      when OTHERS then
        Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Round','������ ��� �������: '||sqlerrm,dwh.uc.c_BoolTrue));
        log.EndLevel;
        TSRPException.RaiseException( p_ExceptionCode => 'EDocumentAction', p_Param1 => '��� ������: '||p_id_rpt_type );
    end;
  end Ch00Round;


  -- ��� ������� ����� - � �������������� ��������� (������ �����)
    procedure Ch00Adjust
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
  -- ������ ����� � ������� �����
  -- ����������� ���������  ������ ���������. ������ ���������� ���.

    Log           dwh.TCBREventLog := dwh.TCBREventLog(p_id_document); -- ���
    l_id_rpt_type_ofc_norm dwh.ud.id := NULL; -- ID ����� � ��������� ���������

  begin
    -- ��������� �������� ������ �� "����������� ��������"
    begin
      -- ��������� ��������-������
      -- ���������� ��� ������ ���������� (���������)

      -- ���������� �� ����� � ��������� ���������. �������� ������������ ����������� (�������������� ����������).
      select ip_rpt_type
        into l_id_rpt_type_ofc_norm
        from dwh.det_rpt_type drt
       where rpt_type_code = 'OFC_NORM' 
             and p_dtClose between drt.dt_open and drt.dt_close;

      if (p_actiondir = uc.c_QUEActionDirDo) then
        Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Adjust', '��������� ������ ��������.'));
        log.BeginLevel;
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

       Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Adjust', '���������� ��������� ������� � �������������� ��������� � ������� ������ '));
       insert into dwh.agg_cbr410ch#( id_document, 
                                      id_rpt_type, 
                                      dt, 
                                      chapter_num, 
                                      row_num, 
                                      row_code, 
                                      sector_code, 
                                      country_code, 
                                      cur_code, 
                                      val_rst)
        select  -- parallel(8)
          p_id_document as id_document,
          p_id_rpt_type as id_rpt_type,
          p_dtClose as dt,
          agg.chapter_num as chapter_num,
          agg.row_num as row_num,
          agg.row_code as row_code4,
          agg.sector_code as sector_code,
          agg.country_code as country_code,
          agg.cur_code as cur_code,
          agg.val_rst as val_rst
        from DWH.Agg_Cbr410ch# agg
        where agg.id_document = p_id_document 
              and agg.id_rpt_type = l_id_rpt_type_ofc_norm;
        commit;


        Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Adjust', '���������� ������� ��������.'));
        log.EndLevel;
      end if;

      if (p_actiondir = uc.c_QUEActionDirUndo) then
        Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Adjust', '��������� ����� ������� ��������.'));
        log.BeginLevel;
        -- ��������� ��������-�����
        delete dwh.agg_cbr410ch# t
         where t.id_document = p_id_document
           and t.id_rpt_type = p_id_rpt_type;
        commit;

        Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Adjust', '���������� ������ ������� ��������.'));
        log.EndLevel;
      end if;

    exception
      when OTHERS then
        Log.AddLogRowA(dwh.TCBREventTypeGeneralized('Ch00Adjust','������ ��� �������: '||sqlerrm,dwh.uc.c_BoolTrue));
        log.EndLevel;
        TSRPException.RaiseException( p_ExceptionCode => 'EDocumentAction', p_Param1 => '��� ������: '||p_id_rpt_type );
    end;
  end Ch00Adjust;

end CBR_F410_MAV;
/
