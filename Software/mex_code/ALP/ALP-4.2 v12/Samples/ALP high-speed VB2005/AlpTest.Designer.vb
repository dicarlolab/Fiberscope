<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()> _
Partial Class AlpTest
    Inherits System.Windows.Forms.Form

    'Form overrides dispose to clean up the component list.
    <System.Diagnostics.DebuggerNonUserCode()> _
    Protected Overrides Sub Dispose(ByVal disposing As Boolean)
        If disposing AndAlso components IsNot Nothing Then
            components.Dispose()
        End If
        MyBase.Dispose(disposing)
    End Sub

    'Required by the Windows Form Designer
    Private components As System.ComponentModel.IContainer

    'NOTE: The following procedure is required by the Windows Form Designer
    'It can be modified using the Windows Form Designer.  
    'Do not modify it using the code editor.
    <System.Diagnostics.DebuggerStepThrough()> _
    Private Sub InitializeComponent()
        Me.Alloc = New System.Windows.Forms.Button
        Me.Pattern1 = New System.Windows.Forms.Button
        Me.Pattern2 = New System.Windows.Forms.Button
        Me.Free = New System.Windows.Forms.Button
        Me.SuspendLayout()
        '
        'Alloc
        '
        Me.Alloc.Location = New System.Drawing.Point(12, 12)
        Me.Alloc.Name = "Alloc"
        Me.Alloc.Size = New System.Drawing.Size(102, 23)
        Me.Alloc.TabIndex = 0
        Me.Alloc.Text = "&Alloc"
        Me.Alloc.UseVisualStyleBackColor = True
        '
        'Pattern1
        '
        Me.Pattern1.Location = New System.Drawing.Point(12, 43)
        Me.Pattern1.Name = "Pattern1"
        Me.Pattern1.Size = New System.Drawing.Size(102, 23)
        Me.Pattern1.TabIndex = 1
        Me.Pattern1.Text = "Pattern &1"
        Me.Pattern1.UseVisualStyleBackColor = True
        '
        'Pattern2
        '
        Me.Pattern2.Location = New System.Drawing.Point(12, 74)
        Me.Pattern2.Name = "Pattern2"
        Me.Pattern2.Size = New System.Drawing.Size(102, 23)
        Me.Pattern2.TabIndex = 2
        Me.Pattern2.Text = "Pattern &2"
        Me.Pattern2.UseVisualStyleBackColor = True
        '
        'Free
        '
        Me.Free.Location = New System.Drawing.Point(12, 105)
        Me.Free.Name = "Free"
        Me.Free.Size = New System.Drawing.Size(102, 23)
        Me.Free.TabIndex = 3
        Me.Free.Text = "&Free"
        Me.Free.UseVisualStyleBackColor = True
        '
        'AlpTest
        '
        Me.AutoScaleDimensions = New System.Drawing.SizeF(6.0!, 13.0!)
        Me.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font
        Me.ClientSize = New System.Drawing.Size(126, 147)
        Me.Controls.Add(Me.Free)
        Me.Controls.Add(Me.Pattern2)
        Me.Controls.Add(Me.Pattern1)
        Me.Controls.Add(Me.Alloc)
        Me.Name = "AlpTest"
        Me.Text = "ALP Test"
        Me.ResumeLayout(False)

    End Sub
    Friend WithEvents Alloc As System.Windows.Forms.Button
    Friend WithEvents Pattern1 As System.Windows.Forms.Button
    Friend WithEvents Pattern2 As System.Windows.Forms.Button
    Friend WithEvents Free As System.Windows.Forms.Button

End Class
